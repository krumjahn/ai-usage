"""Finder presentation only; dmgbuild is a packaging dependency, not an app dependency."""
from pathlib import Path

staging = Path(defines["staging"])
format = "UDZO"
compression_level = 9
filesystem = "HFS+"
files = [str(staging / "AI Usage.app"), str(staging / "Read Me.txt")]
symlinks = {"Applications": "/Applications"}
icon = str(staging / "AI Usage.app/Contents/Resources/AppIcon.icns")
background = "#f6f5f2"
window_rect = ((180, 160), (560, 360))
show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False
default_view = "icon-view"
arrange_by = None
icon_size = 80
text_size = 14
label_pos = "bottom"
icon_locations = {
    "AI Usage.app": (140, 105),
    "Applications": (420, 105),
    "Read Me.txt": (280, 215),
}
