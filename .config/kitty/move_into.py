"""Kitty kitten that moves the active window into its neighbour's split.

Mirrors Hyprland dwindle's ``movewindow``: the active window drops into the neighbour's
slot, and the neighbour is split along its longer side. Kitty's own ``move_window`` only
swaps windows.

Usage, in ``kitty.conf``::

    map ctrl+shift+alt+h kitten move_into.py left

Relies on kitty internals (``insert_window_next_to`` and friends), last checked against
kitty 0.49.2. After a kitty upgrade run ``kitty +launch tests/test_move_into.py``; CI runs
it weekly.
"""
from kittens.tui.handler import result_handler


def main(args: list[str]) -> None:
    # Kitty requires a `main` in every kitten, even a no_ui one that only has handle_result.
    pass


@result_handler(no_ui=True)
def handle_result(args: list[str], answer: str, target_window_id: int, boss) -> None:
    """Move the active window into the neighbouring window's split.

    In the ``splits`` layout the neighbour is split along its longer side and the active
    window is inserted there. Other layouts fall back to kitty's plain window swap.
    Nothing happens, and nothing is raised, if there is no active window, no neighbour in
    that direction, or the neighbour has no geometry yet.

    Args:
        args: ``['move_into.py', direction]``, where direction is ``left``, ``right``,
            ``up`` or ``down``.
        answer: Unused. Required by the ``result_handler`` signature.
        target_window_id: Unused. Required by the ``result_handler`` signature.
        boss: Kitty's ``Boss``, used to reach the active tab.

    Raises:
        IndexError: If ``args`` has no direction, which means a typo in the ``map`` line.
            Left unguarded on purpose so a misconfiguration fails loudly.
    """
    # Kitty names the vertical edges top/bottom, not up/down.
    direction = {'up': 'top', 'down': 'bottom'}.get(args[1], args[1])
    tab = boss.active_tab
    if tab is None or tab.active_window is None:
        return
    if tab.current_layout.name != 'splits':
        tab.move_window(direction)
        return
    gid = tab.neighboring_group_id(direction)
    if gid is None:
        return
    dest = tab.windows.active_window_in_group_id(gid)
    grp = tab.windows.group_for_id(gid)
    g = grp.geometry if grp else None
    if dest is None or g is None:
        return
    # A wide neighbour is split side by side (kitty calls this `horizontal`); a tall one
    # is split top/bottom.
    side_by_side = (g.right - g.left) > (g.bottom - g.top)
    # Moving along the split axis lands on the near edge: right of the neighbour when moving
    # left, below it when moving up. Moving across the axis lands after it (right or below).
    if side_by_side == (direction in ('left', 'right')):
        after = direction in ('left', 'top')
    else:
        after = True
    tab.current_layout.insert_window_next_to(tab.windows, tab.active_window, dest, side_by_side, after)
    tab.relayout()
