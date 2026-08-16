#ifndef FLUTTER_look_bookLICATION_H_
#define FLUTTER_look_bookLICATION_H_

#include <gtk/gtk.h>

G_DECLARE_FINAL_TYPE(MyApplication, look_booklication, MY, APPLICATION,
                     GtkApplication)

/**
 * look_booklication_new:
 *
 * Creates a new Flutter-based application.
 *
 * Returns: a new #MyApplication.
 */
MyApplication* look_booklication_new();

#endif  // FLUTTER_look_bookLICATION_H_
