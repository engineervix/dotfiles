import os
print("font_size 18.0" if os.environ.get("KITTY_OS") == "macos" else "font_size 14.0")
