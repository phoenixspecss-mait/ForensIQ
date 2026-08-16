/**
 * Sync creator_profiles/ (Firebase Realtime Database) → Algolia
 * ─────────────────────────────────────────────────────────────
 * This runs server-side as a Cloud Function, not from the Flutter app.
 * Two reasons:
 *   1. The Algolia Admin API key can write to your index — it must never
 *      ship inside a client app / APK where it can be extracted.
 *   2. RTDB triggers fire exactly once per write, server-side, so the
 *      index can never drift out of sync just because a phone lost
 *      connectivity mid-sync.
 *
 * Deploy:
 *   cd functions && npm install
 *   firebase functions:secrets:set ALGOLIA_APP_ID
 *   firebase functions:secrets:set ALGOLIA_ADMIN_KEY
 *   firebase deploy --only functions
 *
 * Config (do NOT commit real keys):
 *   - ALGOLIA_APP_ID / ALGOLIA_ADMIN_KEY are set as secrets (above) — the
 *     admin key can write to your index, so it must never sit in plain
 *     text in .env or source control.
 *   - ALGOLIA_INDEX_NAME is non-secret and lives in functions/.env
 *     (defaults to "creator_profiles" if unset).
 *
 * `functions.config()` is removed as of firebase-functions v7 — this uses
 * the newer `firebase-functions/params` API instead.
 */
const { onValueWritten, onValueCreated } = require('firebase-functions/v2/database');
const { onRequest, onCall, HttpsError } = require('firebase-functions/v2/https');
const { defineSecret, defineString } = require('firebase-functions/params');
const { logger } = require('firebase-functions');
const admin = require('firebase-admin');
const algoliasearch = require('algoliasearch');
const axios = require('axios');
admin.initializeApp();
const ALGOLIA_APP_ID = defineSecret('ALGOLIA_APP_ID');
const ALGOLIA_ADMIN_KEY = defineSecret('ALGOLIA_ADMIN_KEY');
const ALGOLIA_INDEX_NAME = defineString('ALGOLIA_INDEX_NAME', {
  default: 'creator_profiles',
});
/**
 * Flattens one creator_profiles/$uid record into the shape Algolia should
 * index. Keep this list explicit (rather than spreading the whole RTDB
 * object) so slot-map internals like portfolio_images/reels never leak
 * into search results, and so Algolia record size stays small.
 */
function toAlgoliaRecord(uid, profile) {
  return {
    objectID: uid, // Algolia's required unique id — reuse the Firebase uid
    full_name: profile.full_name || '',
    bio: profile.bio || '',
    city: profile.city || '',
    skills: profile.skills || [],
    rate_chart: profile.rate_chart || {},
    followers: profile.followers || 0,
    is_sponsored: profile.is_sponsored || false,
    _geoloc:
      profile.latitude != null && profile.longitude != null
        ? { lat: profile.latitude, lng: profile.longitude }
        : undefined,
    updated_at: profile.updated_at || Date.now(),
  };
}
// Fires on create, update, AND delete of any field under creator_profiles/$uid.
exports.syncCreatorProfileOnWrite = onValueWritten(
  {
    ref: '/creator_profiles/{uid}',
    secrets: [ALGOLIA_APP_ID, ALGOLIA_ADMIN_KEY],
  },
  async (event) => {
    const uid = event.params.uid;
    const client = algoliasearch(ALGOLIA_APP_ID.value(), ALGOLIA_ADMIN_KEY.value());
    const index = client.initIndex(ALGOLIA_INDEX_NAME.value());
    // Node deleted entirely → remove it from the index too.
    if (!event.data.after.exists()) {
      await index.deleteObject(uid);
      return null;
    }
    const profile = event.data.after.val();
    const record = toAlgoliaRecord(uid, profile);
    await index.saveObject(record);
    return null;
  },
);

/**
 * Bill profile-view impressions against a creator's ad budget
 * ─────────────────────────────────────────────────────────────
 * Fires once per new node under /profile_views/{creatorId}/{viewId}.
 * A view is written by the client when a recruiter opens a creator's
 * profile (see database.rules.json — append-only, one write per viewId,
 * viewerUid must match auth.uid, cannot view your own profile).
 *
 * This function is the only thing that ever writes to /ad_accounts —
 * database.rules.json disables direct client writes there.
 *
 * CPM = cost per 1000 impressions.
 *   General (untargeted) view: recruiter found the creator via
 *   generic browse/search.        → ₹150 CPM → ₹0.15 / view
 *   Targeted/localized view: recruiter used a location/category filter
 *   matching the creator's target. → ₹225 CPM → ₹0.225 / view
 */
const GENERAL_CPM = 150;
const TARGETED_CPM = 225;

function costPerImpression(targeted) {
  return (targeted ? TARGETED_CPM : GENERAL_CPM) / 1000;
}

exports.onProfileViewCreated = onValueCreated(
  '/profile_views/{creatorId}/{viewId}',
  async (event) => {
    const { creatorId, viewId } = event.params;
    const view = event.data.val();

    if (!view || view.billed) {
      // Already processed (retry) or malformed — nothing to do.
      return null;
    }

    const db = admin.database();
    const viewRef = db.ref(`profile_views/${creatorId}/${viewId}`);
    const budgetRef = db.ref(`ad_accounts/${creatorId}`);

    // ── Idempotency guard ────────────────────────────────────────────
    // RTDB-triggered functions can retry on transient failure — claim
    // the view by flipping `billed` in a transaction first, so the same
    // impression can never be charged twice.
    const claim = await viewRef.child('billed').transaction((current) => {
      if (current === true) {
        return; // abort — someone already claimed this view
      }
      return true;
    });

    if (!claim.committed) {
      logger.info(`View ${viewId} for ${creatorId} already billed, skipping.`);
      return null;
    }

    const targeted = view.targeted === true;
    const cost = costPerImpression(targeted);

    // ── Decrement budget atomically ─────────────────────────────────
    const result = await budgetRef.transaction((account) => {
      if (account === null) {
        // No ad account/wallet set up for this creator — nothing to
        // decrement, just leave it as-is.
        return account;
      }

      const currentBudget = account.budget ?? 0;
      const totalImpressions = account.totalImpressions ?? 0;
      const generalImpressions = account.generalImpressions ?? 0;
      const targetedImpressions = account.targetedImpressions ?? 0;
      const totalSpend = account.totalSpend ?? 0;

      if (currentBudget <= 0) {
        // Budget already exhausted — still count the impression for
        // analytics, but don't let spend go negative.
        return {
          ...account,
          budget: 0,
          status: 'exhausted',
          totalImpressions: totalImpressions + 1,
          generalImpressions: generalImpressions + (targeted ? 0 : 1),
          targetedImpressions: targetedImpressions + (targeted ? 1 : 0),
        };
      }

      const newBudget = Math.max(0, currentBudget - cost);

      return {
        ...account,
        budget: Math.round(newBudget * 10000) / 10000, // avoid float drift
        status: newBudget <= 0 ? 'exhausted' : 'active',
        totalImpressions: totalImpressions + 1,
        generalImpressions: generalImpressions + (targeted ? 0 : 1),
        targetedImpressions: targetedImpressions + (targeted ? 1 : 0),
        totalSpend: Math.round((totalSpend + cost) * 10000) / 10000,
      };
    });

    if (!result.committed) {
      logger.error(`Budget transaction failed for creator ${creatorId}`);
      return null;
    }

    if (result.snapshot.val() === null) {
      logger.warn(`Creator ${creatorId} has no ad_accounts entry — impression logged, nothing billed.`);
      return null;
    }

    logger.info(
      `Billed ${creatorId} ₹${cost} (${targeted ? 'targeted' : 'general'} view). ` +
      `Remaining budget: ₹${result.snapshot.child('budget').val()}`
    );
    return null;
  },
);

/**
 * ── Instamojo Payment Gateway Integration Cloud Functions ──────────────────
 */

const INSTAMOJO_API_KEY = defineSecret('INSTAMOJO_API_KEY');
const INSTAMOJO_AUTH_TOKEN = defineSecret('INSTAMOJO_AUTH_TOKEN');
const INSTAMOJO_IS_SANDBOX = defineString('INSTAMOJO_IS_SANDBOX', { default: 'true' });

function getInstamojoBaseUrl() {
  return INSTAMOJO_IS_SANDBOX.value() === 'true'
    ? 'https://test.instamojo.com/api/1.1'
    : 'https://www.instamojo.com/api/1.1';
}

/**
 * Create Instamojo Payment Order
 */
exports.createInstamojoOrder = onCall(
  { secrets: [INSTAMOJO_API_KEY, INSTAMOJO_AUTH_TOKEN] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'User must be authenticated to create a payment order.');
    }

    const { amount, purpose, buyerName, buyerEmail, buyerPhone } = request.data;
    const uid = request.auth.uid;

    if (!amount || !purpose) {
      throw new HttpsError('invalid-argument', 'Amount and purpose are required.');
    }

    const baseUrl = getInstamojoBaseUrl();
    const apiKey = INSTAMOJO_API_KEY.value();
    const authToken = INSTAMOJO_AUTH_TOKEN.value();

    const formData = new URLSearchParams();
    formData.append('purpose', purpose);
    formData.append('amount', Number(amount).toFixed(2));
    formData.append('buyer_name', buyerName || 'Lookbook User');
    formData.append('email', buyerEmail || 'user@lookbook.com');

    let formattedPhone = '9820098200';
    if (buyerPhone) {
      const cleanPhone = buyerPhone.toString().replace(/\D/g, '');
      if (cleanPhone.length >= 10) {
        const last10 = cleanPhone.slice(-10);
        if (/^[6-9]\d{9}$/.test(last10) && !/^(\d)\1{9}$/.test(last10) && last10 !== '9876543210' && last10 !== '1234567890') {
          formattedPhone = last10;
        }
      }
    }
    formData.append('phone', formattedPhone);
    formData.append('redirect_url', 'https://lookbook-app.web.app/instamojo-redirect');
    formData.append('send_email', 'False');
    formData.append('send_sms', 'False');

    try {
      const response = await axios.post(`${baseUrl}/payment-requests/`, formData.toString(), {
        headers: {
          'X-Api-Key': apiKey,
          'X-Auth-Token': authToken,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      });

      if (response.data && response.data.success) {
        const pr = response.data.payment_request;
        // Save pending order record in RTDB
        await admin.database().ref(`payments/${uid}/${pr.id}`).set({
          uid,
          payment_request_id: pr.id,
          amount: Number(amount),
          purpose,
          status: 'pending',
          created_at: Date.now(),
        });

        return {
          success: true,
          paymentRequestId: pr.id,
          longUrl: pr.longurl,
          status: pr.status,
        };
      } else {
        return {
          success: false,
          error: response.data.message || 'Failed to create payment order.',
        };
      }
    } catch (error) {
      logger.error('Instamojo Order Creation Error:', error.response?.data || error.message);
      throw new HttpsError('internal', error.response?.data?.message || error.message);
    }
  }
);

/**
 * Verify Instamojo Payment Status
 */
exports.verifyInstamojoPayment = onCall(
  { secrets: [INSTAMOJO_API_KEY, INSTAMOJO_AUTH_TOKEN] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'User must be authenticated.');
    }

    const { paymentRequestId, paymentId } = request.data;
    const uid = request.auth.uid;

    if (!paymentRequestId || !paymentId) {
      throw new HttpsError('invalid-argument', 'paymentRequestId and paymentId are required.');
    }

    const baseUrl = getInstamojoBaseUrl();
    const apiKey = INSTAMOJO_API_KEY.value();
    const authToken = INSTAMOJO_AUTH_TOKEN.value();

    try {
      const response = await axios.get(
        `${baseUrl}/payment-requests/${paymentRequestId}/${paymentId}/`,
        {
          headers: {
            'X-Api-Key': apiKey,
            'X-Auth-Token': authToken,
          },
        }
      );

      const isCredit =
        response.data?.success &&
        response.data?.payment?.status?.toUpperCase() === 'CREDIT';

      if (isCredit) {
        const now = Date.now();
        const oneYear = 365 * 24 * 60 * 60 * 1000;

        // Activate premium status
        await admin.database().ref(`creator_profiles/${uid}`).update({
          is_premium: true,
          premium_since: now,
          premium_until: now + oneYear,
          subscription_payment_id: paymentId,
          subscription_payment_request_id: paymentRequestId,
          updated_at: now,
        });

        await admin.database().ref(`users/${uid}`).update({
          is_premium: true,
          premium_until: now + oneYear,
        });

        await admin.database().ref(`payments/${uid}/${paymentRequestId}`).update({
          payment_id: paymentId,
          status: 'completed',
          updated_at: now,
        });

        return { success: true, isPaid: true, message: 'Subscription activated!' };
      }

      return { success: true, isPaid: false, message: 'Payment status is not CREDIT.' };
    } catch (error) {
      logger.error('Instamojo Verify Error:', error.response?.data || error.message);
      throw new HttpsError('internal', error.message);
    }
  }
);

/**
 * Instamojo Server Webhook Endpoint
 */
exports.instamojoWebhook = onRequest(async (req, res) => {
  try {
    const { payment_id, payment_request_id, status } = req.body;
    logger.info(`Received Instamojo Webhook for request ${payment_request_id}, payment ${payment_id}, status: ${status}`);

    if (status?.toUpperCase() === 'CREDIT' && payment_request_id) {
      // Find order in payments database
      const snap = await admin.database().ref('payments').get();
      if (snap.exists()) {
        const payments = snap.val();
        for (const uid in payments) {
          if (payments[uid][payment_request_id]) {
            const now = Date.now();
            const oneYear = 365 * 24 * 60 * 60 * 1000;

            await admin.database().ref(`creator_profiles/${uid}`).update({
              is_premium: true,
              premium_since: now,
              premium_until: now + oneYear,
              subscription_payment_id: payment_id,
              subscription_payment_request_id: payment_request_id,
              updated_at: now,
            });

            await admin.database().ref(`users/${uid}`).update({
              is_premium: true,
              premium_until: now + oneYear,
            });

            await admin.database().ref(`payments/${uid}/${payment_request_id}`).update({
              payment_id: payment_id,
              status: 'completed',
              updated_at: now,
            });

            logger.info(`Webhook successfully activated Premium for user ${uid}`);
            break;
          }
        }
      }
    }
    return res.status(200).send({ received: true });
  } catch (err) {
    logger.error('Webhook processing error:', err);
    return res.status(500).send({ error: err.message });
  }
});