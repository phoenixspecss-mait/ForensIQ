/**
 * One-time backfill: pushes every EXISTING creator_profiles/$uid record
 * into Algolia. Run this once, before or right after deploying the
 * onWrite function — the function only catches writes from that point
 * forward, so profiles created earlier need this to appear in search.
 *
 * Usage:
 *   cd functions
 *   npm install
 *   GOOGLE_APPLICATION_CREDENTIALS=./service-account.json \
 *   ALGOLIA_APP_ID=... ALGOLIA_ADMIN_KEY=... ALGOLIA_INDEX_NAME=creator_profiles \
 *   node backfill.js
 */

const admin = require('firebase-admin');
const algoliasearch = require('algoliasearch');

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  databaseURL: process.env.FIREBASE_DATABASE_URL, // e.g. https://look-book2.firebaseio.com
});

const client = algoliasearch(
  process.env.ALGOLIA_APP_ID,
  process.env.ALGOLIA_ADMIN_KEY,
);
const index = client.initIndex(process.env.ALGOLIA_INDEX_NAME || 'creator_profiles');

function toAlgoliaRecord(uid, profile) {
  return {
    objectID: uid,
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

async function run() {
  const snap = await admin.database().ref('creator_profiles').get();
  if (!snap.exists()) {
    console.log('No creator_profiles found — nothing to backfill.');
    return;
  }

  const all = snap.val();
  const records = Object.entries(all).map(([uid, profile]) =>
    toAlgoliaRecord(uid, profile),
  );

  // saveObjects batches internally, so this is safe even for thousands
  // of profiles.
  const { objectIDs } = await index.saveObjects(records);
  console.log(`Backfilled ${objectIDs.length} creator profiles into Algolia.`);
}

run()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('Backfill failed:', err);
    process.exit(1);
  });