import Base

# Custom effects on the Bend window (Linux/X11). screen.c has the implementation.

# Remove the fixed window size, so that the window manager can tile the window.
def Screen.setup(window: Window) -> IO(Window):
  import "./screen.c"

# Call one time for each frame. It follows the window size and, when the game has focus,
# holds the mouse at the center. It returns (width, height, dx, dy, focus):
# dx and dy have 32768 added because U32 has no sign, and focus is 1 or 0.
def Screen.sync(window: Window) -> IO(Window & U32 & U32 & U32 & U32 & U32):
  import "./screen.c"
