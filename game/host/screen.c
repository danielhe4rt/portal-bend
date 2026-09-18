// Portal: resizable window and mouse held at the center
// ======================================================

#if defined(__linux__) && !defined(__OBJC__)

#ifndef BendWin
#define BendWin BendWin
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/keysym.h>

typedef struct {
  Display* dpy;
  Window   win;
  Atom     del;
  XImage*  img;
  u32      n;
  u32      cap;
  u32*     evs;
} BendWin;
#endif

static Cursor screen_blank;
static bool   screen_grabbed;

// Hyprland decides to float a window when the window maps. Unmap it and map it again without the fixed size.
static void screen_setup(BendWin* win) {
  XSizeHints hints = { .flags = PMinSize, .min_width = 320, .min_height = 180 };
  XUnmapWindow(win->dpy, win->win);
  XSetWMNormalHints(win->dpy, win->win, &hints);
  XMapRaised(win->dpy, win->win);
  char   none[1] = { 0 };
  XColor black   = { 0 };
  Pixmap dot     = XCreateBitmapFromData(win->dpy, win->win, none, 1, 1);
  screen_blank   = XCreatePixmapCursor(win->dpy, dot, dot, &black, &black, 0, 0);
  XFreePixmap(win->dpy, dot);
  XFlush(win->dpy);
}

static void screen_resize(BendWin* win, u32 w, u32 h) {
  int scr = DefaultScreen(win->dpy);
  XDestroyImage(win->img);
  win->img = XCreateImage(win->dpy, DefaultVisual(win->dpy, scr),
    DefaultDepth(win->dpy, scr), ZPixmap, 0, io_mem(calloc(w * h, 4)), w, h,
    32, w * 4);
  win->img->byte_order = LSBFirst;
}

static void screen_release(BendWin* win) {
  if (screen_grabbed) {
    XUngrabPointer(win->dpy, CurrentTime);
    XUndefineCursor(win->dpy, win->win);
    screen_grabbed = false;
  }
}

// With focus: hold the pointer in the window, hide the cursor and move the pointer back to the center.
// XWayland emulates XWarpPointer only when the pointer is grabbed and the cursor is hidden.
static void screen_capture(BendWin* win, u32 w, u32 h, int* dx, int* dy) {
  int cx = (int)w / 2;
  int cy = (int)h / 2;
  if (!screen_grabbed) {
    int got = XGrabPointer(win->dpy, win->win, True,
      ButtonPressMask | ButtonReleaseMask | PointerMotionMask, GrabModeAsync,
      GrabModeAsync, win->win, screen_blank, CurrentTime);
    screen_grabbed = got == GrabSuccess;
    XDefineCursor(win->dpy, win->win, screen_blank);
  } else {
    Window root, child;
    int    rx, ry, x, y;
    u32    mask;
    if (XQueryPointer(win->dpy, win->win, &root, &child, &rx, &ry, &x, &y,
      &mask)) {
      *dx = x - cx;
      *dy = y - cy;
    }
  }
  XWarpPointer(win->dpy, None, win->win, 0, 0, 0, 0, cx, cy);
}

// The window manager can give focus to a window that contains the game window.
static bool screen_focused(BendWin* win) {
  Window focus;
  int    revert;
  XGetInputFocus(win->dpy, &focus, &revert);
  Window at = win->win;
  while (at != None) {
    if (at == focus) {
      return true;
    }
    Window  root, parent, *kids;
    u32     n;
    if (!XQueryTree(win->dpy, at, &root, &parent, &kids, &n)) {
      return false;
    }
    if (kids) {
      XFree(kids);
    }
    at = parent == root ? None : parent;
  }
  return false;
}

static void screen_sync(BendWin* win, u32* w, u32* h, int* dx, int* dy,
  u32* focused) {
  XWindowAttributes at;
  XGetWindowAttributes(win->dpy, win->win, &at);
  *w = at.width > 16 ? (u32)at.width : 16;
  *h = at.height > 16 ? (u32)at.height : 16;
  if (*w != (u32)win->img->width || *h != (u32)win->img->height) {
    screen_resize(win, *w, *h);
  }
  *focused = screen_focused(win);
  if (*focused) {
    screen_capture(win, *w, *h, dx, dy);
  } else {
    screen_release(win);
  }
  XFlush(win->dpy);
}

#endif

Term screen_setup_run(Env e, Term* f, IoWork* w) {
#if defined(__linux__) && !defined(__OBJC__)
  screen_setup((BendWin*)io_hand_v(f[0]));
#endif
  return f[0];
}

Term screen_sync_run(Env e, Term* f, IoWork* w) {
  u32 width = 1280, height = 720, focused = 0;
  int dx = 0, dy = 0;
#if defined(__linux__) && !defined(__OBJC__)
  screen_sync((BendWin*)io_hand_v(f[0]), &width, &height, &dx, &dy, &focused);
#endif
  Term tail = io_tup(e, (Term)(u32)(dy + 32768), (Term)focused);
  tail      = io_tup(e, (Term)(u32)(dx + 32768), tail);
  tail      = io_tup(e, (Term)height, tail);
  tail      = io_tup(e, (Term)width, tail);
  return io_tup(e, f[0], tail);
}

static void __attribute__((constructor)) screen_use(void) {
  io_eff(CID_SCREEN_SETUP, screen_setup_run, 0);
  io_eff(CID_SCREEN_SYNC, screen_sync_run, 0);
}
