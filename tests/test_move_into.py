# Tests for .config/kitty/move_into.py against kitty's real Splits layout.
# They fail if a kitty upgrade renames or re-signatures the internals the kitten uses.
# Run with kitty's own Python (kitty runs with -OO, so use unittest methods, never `assert`):
#   kitty +launch tests/test_move_into.py                           # all
#   kitty +launch tests/test_move_into.py MoveIntoTest.test_<name>  # one
# The fakes are adapted from kitty's own kitty_tests/layout.py (not shipped in packages).
#
# How to read the diagrams below: each box is a kitty window, the number is its id, and `*`
# marks the active window (the one being moved). The kitten drops the active window into its
# neighbour's slot and splits that neighbour along its LONGER side:
#   - neighbour is tall  -> active window goes above/below it
#   - neighbour is wide  -> active window goes left/right of it
# Moving ALONG the split axis lands on the near edge; moving ACROSS it lands below/right.
# The fake screen is 1500x1100, so a half-width column is 750 wide: "wide" if it is also split
# top/bottom (750x550), "tall" if it takes the full height (750x1100).
import copy
import sys
import types
import unittest
from pathlib import Path
from types import SimpleNamespace

from kitty.config import defaults
from kitty.fast_data_types import Region, set_options
from kitty.layout.base import lgd
from kitty.layout.interface import Splits
from kitty.tabs import Tab as RealTab
from kitty.types import WindowGeometry
from kitty.window import EdgeWidths
from kitty.window_list import WindowList, reset_group_id_counter

set_options(defaults)

KITTEN = Path(__file__).resolve().parent.parent / '.config/kitty/move_into.py'
# Compile the source directly: importing it would reuse a stale .pyc (keyed on mtime in whole
# seconds + size), which hides same-length edits.
move_into = types.ModuleType('move_into')
exec(compile(KITTEN.read_text(), str(KITTEN), 'exec'), move_into.__dict__)


class FakeWindow:
    """Stand-in for kitty's Window: just the attributes and methods ``Splits`` touches."""

    show_title_bar = False

    def __init__(self, i):
        self.id = i
        self.serialized_id = 0
        self.overlay_for = None
        self.overlay_window_id = None
        self.is_visible_in_layout = True
        self.geometry = WindowGeometry(0, 0, 0, 0, 0, 0)
        self.padding = EdgeWidths()
        self.margin = EdgeWidths()
        self.focused = False

    def focus_changed(self, f): self.focused = f
    def effective_border(self): return 1
    def effective_padding(self, e): return 1
    def effective_margin(self, e): return 1
    def default_margin(self, e): return 1
    def set_visible_in_layout(self, v): self.is_visible_in_layout = bool(v)
    def set_geometry(self, g): self.geometry = g


class FakeTab:
    """Stand-in for kitty's Tab, only so the window list can call back into the layout."""

    def active_window_changed(self):
        self.current_layout.update_visibility(self.windows)


def stack(a, b):  # a over b
    return {'horizontal': False, 'one': a, 'two': b}


def row(a, b):  # a beside b (kitty omits horizontal=True when serializing)
    return {'one': a, 'two': b}


class MoveIntoTest(unittest.TestCase):
    def move(self, shape, active, direction):
        """Build a 3-window Splits layout from `shape`, run the kitten, return the new shape."""
        layout = Splits(1, 1)
        layout.set_active_window_in_os_window = lambda idx: None
        layout.swap_windows_in_os_window = lambda a, b: None
        t = FakeTab()
        t.current_layout = layout
        t.windows = windows = WindowList(t)
        windows.tab_mem = t
        reset_group_id_counter()
        for i in range(3):  # every diagram below uses windows 1, 2 and 3
            windows.add_window(FakeWindow(i + 1))
        windows.set_active_group_idx(0)  # the active window is set per test, after layout
        layout.pairs_root.unserialize(copy.deepcopy(shape), lambda x: x)  # may consume its input

        def set_dimensions(all_windows):
            lgd.central = Region((0, 0, 1500, 1100, 1500, 1100))
            lgd.cell_width, lgd.cell_height = 10, 20
        layout._set_dimensions = set_dimensions
        tab = SimpleNamespace(current_layout=layout, windows=windows, relayout=lambda: layout(windows))
        tab.relayout()
        windows.set_active_window_group_for(windows.id_map[active])
        tab.active_window = windows.active_window
        tab.most_recent_group = lambda c: RealTab.most_recent_group(tab, c)
        tab.neighboring_group_id = lambda w: RealTab.neighboring_group_id(tab, w)
        move_into.handle_result(['move_into.py', direction], '', 0, SimpleNamespace(active_tab=tab))
        return layout.pairs_root.serialize()

    # Move 2 right. 3 is tall (full height), and 2 crosses its split axis, so 2 lands below 3.
    #
    #   ┌─────┬─────┐         ┌─────┬─────┐
    #   │  1  │     │         │     │  3  │
    #   ├─────┤  3  │   -->   │  1  ├─────┤
    #   │  2* │     │         │     │  2* │
    #   └─────┴─────┘         └─────┴─────┘
    def test_right_into_tall_neighbour_lands_below_it(self):
        got = self.move({'one': stack(1, 2), 'two': 3}, 2, 'right')
        self.assertEqual(got, {'one': 1, 'two': stack(3, 2)})

    # Move 2 left: the reverse of the test above. 1 is tall, so 2 lands below 1.
    #
    #   ┌─────┬─────┐         ┌─────┬─────┐
    #   │     │  3  │         │  1  │     │
    #   │  1  ├─────┤   -->   ├─────┤  3  │
    #   │     │  2* │         │  2* │     │
    #   └─────┴─────┘         └─────┴─────┘
    def test_left_into_tall_neighbour_lands_below_it(self):
        got = self.move({'one': 1, 'two': stack(3, 2)}, 2, 'left')
        self.assertEqual(got, {'one': stack(1, 2), 'two': 3})

    # Move 3 up (also checks the `up` -> `top` mapping). 2 is wide (750x550) and 3 crosses its
    # split axis, so 3 lands beside 2, on its right.
    #
    #   ┌─────┬─────┐         ┌─────┬──┬──┐
    #   │     │  2  │         │     │  │  │
    #   │  1  ├─────┤   -->   │  1  │2 │3*│
    #   │     │  3* │         │     │  │  │
    #   └─────┴─────┘         └─────┴──┴──┘
    def test_up_into_wide_neighbour_lands_beside_it(self):
        got = self.move({'one': 1, 'two': stack(2, 3)}, 3, 'up')
        self.assertEqual(got, {'one': 1, 'two': row(2, 3)})

    # Move 3 left. 1 is wide and 3 moves along its split axis, so 3 lands on the near (right)
    # edge of 1, not the far side. With 3 gone, 2 spans the full width underneath.
    #
    #   ┌─────┬─────┐         ┌─────┬─────┐
    #   │  1  │     │         │  1  │ 3*  │
    #   ├─────┤ 3*  │   -->   ├─────┴─────┤
    #   │  2  │     │         │     2     │
    #   └─────┴─────┘         └───────────┘
    def test_left_into_wide_neighbour_lands_on_its_near_edge(self):
        got = self.move({'one': stack(1, 2), 'two': 3}, 3, 'left')
        self.assertEqual(got, stack(row(1, 3), 2))

    # Move 1 left. Nothing is on its left, so nothing happens.
    #
    #   ┌─────┬─────┐         ┌─────┬─────┐
    #   │  1* │     │         │  1* │     │
    #   ├─────┤  3  │   -->   ├─────┤  3  │   (unchanged)
    #   │  2  │     │         │  2  │     │
    #   └─────┴─────┘         └─────┴─────┘
    def test_no_neighbour_leaves_layout_unchanged(self):
        shape = {'one': stack(1, 2), 'two': 3}
        self.assertEqual(self.move(shape, 1, 'left'), shape)


# argv[0] is a placeholder; any further arguments select tests, e.g. MoveIntoTest.test_<name>.
unittest.main(argv=['test_move_into'] + sys.argv[1:])
