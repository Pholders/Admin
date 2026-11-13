import 'dart:async';

import 'package:flutter/material.dart';

/// Shows record details in place of a screen's table instead of in a pop-up.
///
/// [AdminDetailHost] wraps a screen's body (the app shell does this for every
/// screen). Opening a detail hides the body and shows the detail in its
/// place; Back returns to the body exactly as it was left — filters, page and
/// scroll position included, because the body stays mounted while hidden.
///
/// Details stack: a link inside one (an order's prescription) opens on top,
/// and Back steps down one level. Lower levels stay mounted too, so stepping
/// back doesn't fetch them again (a prescription open is audit-logged).
class AdminDetailHost extends StatefulWidget {
  final Widget child;

  const AdminDetailHost({super.key, required this.child});

  @override
  State<AdminDetailHost> createState() => _AdminDetailHostState();
}

class _DetailEntry {
  final WidgetBuilder builder;
  final Completer<void> closed = Completer<void>();
  final GlobalKey key = GlobalKey();

  _DetailEntry(this.builder);
}

class _AdminDetailHostState extends State<AdminDetailHost> {
  final _stack = <_DetailEntry>[];

  Future<void> push(WidgetBuilder builder) {
    final entry = _DetailEntry(builder);
    setState(() => _stack.add(entry));
    return entry.closed.future;
  }

  void pop(_DetailEntry entry) {
    if (!_stack.contains(entry)) return;
    // Closing a lower level closes everything opened from it as well.
    final removed = _stack.sublist(_stack.indexOf(entry));
    setState(() => _stack.removeRange(_stack.indexOf(entry), _stack.length));
    for (final e in removed.reversed) {
      if (!e.closed.isCompleted) e.closed.complete();
    }
  }

  @override
  void dispose() {
    // Leaving the screen with a detail open still runs each opener's cleanup.
    for (final e in _stack.reversed) {
      if (!e.closed.isCompleted) e.closed.complete();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showing = _stack.isNotEmpty;
    return Stack(
      children: [
        Positioned.fill(
          child: Offstage(
            offstage: showing,
            child: TickerMode(enabled: !showing, child: widget.child),
          ),
        ),
        for (var i = 0; i < _stack.length; i++)
          Positioned.fill(
            child: Offstage(
              offstage: i != _stack.length - 1,
              child: TickerMode(
                enabled: i == _stack.length - 1,
                child: AdminDetailScope._(
                  close: () => pop(_stack[i]),
                  depth: i,
                  child: KeyedSubtree(key: _stack[i].key, child: Builder(builder: _stack[i].builder)),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Marks a subtree as an inline detail and knows how to close it.
class AdminDetailScope extends InheritedWidget {
  final VoidCallback close;

  /// 0 for a detail opened from the table, 1 for one opened from that, …
  final int depth;

  const AdminDetailScope._({required this.close, required this.depth, required super.child});

  static AdminDetailScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AdminDetailScope>();

  @override
  bool updateShouldNotify(AdminDetailScope old) => depth != old.depth;
}

/// Opens [builder]'s detail in place of the screen's table. The future
/// completes when it is closed (Back, Done, or leaving the screen).
///
/// Outside an [AdminDetailHost] (a test that pumps a bare widget, or a page
/// without the app shell) it falls back to a dialog, so callers needn't care.
Future<void> showAdminDetail(BuildContext context, WidgetBuilder builder) {
  final host = context.findAncestorStateOfType<_AdminDetailHostState>();
  if (host == null) return showDialog<void>(context: context, builder: builder);
  return host.push(builder);
}

/// Closes the detail [context] belongs to: the inline one if there is one,
/// otherwise the dialog route.
void closeAdminDetail(BuildContext context) {
  final scope = context.getInheritedWidgetOfExactType<AdminDetailScope>();
  if (scope != null) {
    scope.close();
  } else {
    Navigator.pop(context);
  }
}
