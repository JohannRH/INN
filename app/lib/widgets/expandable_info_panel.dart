import 'package:flutter/material.dart';

class ExpandableInfoPanel extends StatefulWidget {
  final List<Widget> children;
  final double initialChildSize;
  final double minChildSize;
  final double maxChildSize;
  final bool snap;

  const ExpandableInfoPanel({
    super.key,
    required this.children,
    this.initialChildSize = 0.35,
    this.minChildSize = 0.2,
    this.maxChildSize = 0.8,
    this.snap = true,
  });

  @override
  State<ExpandableInfoPanel> createState() => ExpandableInfoPanelState();
}

class ExpandableInfoPanelState extends State<ExpandableInfoPanel> {
  late DraggableScrollableController _dragController;

  @override
  void initState() {
    super.initState();
    _dragController = DraggableScrollableController();
  }

  @override
  void dispose() {
    _dragController.dispose();
    super.dispose();
  }

  /// Method to reset the panel to its initial size
  void resetToInitialSize() {
    if (_dragController.isAttached) {
      _dragController.animateTo(
        widget.initialChildSize,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      controller: _dragController,
      initialChildSize: widget.initialChildSize,
      minChildSize: widget.minChildSize,
      maxChildSize: widget.maxChildSize,
      snap: widget.snap,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              // small top handle + visual accent
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 6),
                child: Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),

              // content with horizontal padding so items don't touch edges
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: widget.children,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}