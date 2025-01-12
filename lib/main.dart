import 'dart:ui';

import 'package:flutter/material.dart';

/// Entry point for the application.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

/// [Widget] for building the [MaterialApp].
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: DockDemo(),
    );
  }
}

/// [DockDemo] is the screen [Widget] for the dock.
class DockDemo extends StatelessWidget {
  const DockDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Dock(),
          ),
        ),
      ],
    );
  }
}

/// A model that represents a draggable item within a dock interface.
///
/// A [DockItem] maintains both its current and original positions, making it
/// suitable for drag-and-drop reordering operations. Each item is uniquely
/// identified by a [key] generated from its [label].

/// Dock of reorderable [items].
class Dock extends StatefulWidget {
  const Dock({super.key});

  @override
  State<Dock> createState() => _DockState();
}

/// State of the [Dock] used to manipulate [items].
class _DockState extends State<Dock> {
  /// Index of the hovered [DockItem].
  late int? hoveredIndex;

  /// base height of the [items]
  late double baseItemHeight;

  /// The base translation of the [items] along the positive y-axis
  late double baseTranslationYaxis;

  /// The padding between the [items].
  late double verticleItemsPadding;

  /// [DockItem] items being manipulated.
  List<DockItem> items = [
    DockItem(
        icon: const Icon(Icons.person, color: Colors.white), label: 'Person'),
    DockItem(
        icon: const Icon(Icons.message, color: Colors.white), label: 'Message'),
    DockItem(icon: const Icon(Icons.call, color: Colors.white), label: 'Call'),
    DockItem(
        icon: const Icon(Icons.camera, color: Colors.white), label: 'Camera'),
    DockItem(
        icon: const Icon(Icons.photo, color: Colors.white), label: 'Photo'),
  ];

  /// The [GlobalKey] for the dock in order to check the bounds of the dock
  final GlobalKey _dockKey = GlobalKey();

  /// [isDragging] is a boolean flag to check if the dock is currently being dragged or not.
  bool isDragging = false;

  /// The [Offset] of the drag, used to calculate the new position of the dragged item, defaulted to [Offset.zero]
  Offset dragOffset = Offset.zero;

  /// A boolean flag to check if the dragged [DockItem] should go back to its original position.
  bool goBacktoOriginalPosition = true;

  /// The index of the [DockItem] being dragged.
  int? draggingIndex;

  /// The width of the [Dock].
  late double dockWidth;

  @override
  void initState() {
    super.initState();

    /// Initialize the [hoveredIndex].
    hoveredIndex = null;

    /// Initialize the [baseItemHeight].
    baseItemHeight = 50;

    /// Initialize the base translation along the y-axis.
    baseTranslationYaxis = 0.0;

    /// Initialize the padding between the [items].
    verticleItemsPadding = 10;

    /// Calculate starting positions centered on screen after the [Widget] is built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;
      final itemSpacing = 10;

      final totalWidth = items.length * (baseItemHeight + itemSpacing);
      final startX = ((screenWidth - totalWidth) / 2) + 4;
      final centerY = (screenHeight / 2) - 42;

      /// initialize [DockItem] positions in a horizontal row inside the [Dock]
      for (int i = 0; i < items.length; i++) {
        items[i].position =
            Offset(startX + (i * (baseItemHeight + itemSpacing)), centerY);
        items[i].originalPosition = items[i].position;
      }
      setState(() {});
    });
  }

  ///  Calculates the scaled size and translation along the y-axis of the [DockItem] at the given [index].
  double _getPropertyValue({
    required int index,
    required double baseValue,
    required double maxValue,
    required double nonHoveredMaximumValue,
  }) {
    late final double propertyValue;
    if (hoveredIndex == null) {
      return baseValue;
    }

    final difference = (hoveredIndex! - index).abs();

    /// The number of [items] affected by the hover.
    final itemsAffected = items.length;

    /// When [difference] is `0`, the item is being hovered.
    /// Returns [maxValue] to give it maximum prominence.
    if (difference == 0) {
      propertyValue = maxValue;

      /// When [difference] is within [itemsAffected] range, creates a smooth
      /// transition effect. Items closer to the hovered item receive larger values.
      /// Uses [lerpDouble] to interpolate between [baseValue] and [nonHoveredMaximumValue].
    } else if (difference <= itemsAffected) {
      final ratio = (itemsAffected - difference) / itemsAffected;
      propertyValue = lerpDouble(baseValue, nonHoveredMaximumValue, ratio)!;

      /// When item is outside the affected range, returns [baseValue]
      /// as it should not be influenced by the hover effect.
    } else {
      propertyValue = baseValue;
    }
    return propertyValue;
  }

  @override
  Widget build(BuildContext context) {
    dockWidth = calculateDockWidth();
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedContainer(
          key: _dockKey,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          height: baseItemHeight + 16,
          width: dockWidth,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.black12,
          ),
          padding: const EdgeInsets.all(4),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: verticleItemsPadding),
          child: Stack(
            clipBehavior: Clip.none,
            children: List.generate(items.length, (index) {
              final scaledSize = getScaledSize(index);
              final scale = scaledSize / baseItemHeight;
              final itemPosition = items[index].position;
              if (items[index].icon == null) {
                return SizedBox(
                  height: baseItemHeight,
                  width: baseItemHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }

              /// Determines the animation duration for dock [DockItem].
              ///
              /// Returns a [Duration] of
              ///  `300` milliseconds when [goBacktoOriginalPosition] is true and [DockItem] is
              ///   being dragged ([draggingIndex] != [index]).
              ///  `0` milliseconds during active drag operations for immediate response
              return AnimatedPositioned(
                  duration: Duration(
                      milliseconds:
                          goBacktoOriginalPosition && draggingIndex != index
                              ? 300
                              : 0),
                  key: items[index].key,
                  left: itemPosition.dx,
                  top: itemPosition.dy,
                  child: MouseRegion(
                    onEnter: (event) => setState(() => hoveredIndex = index),
                    onExit: (event) => setState(() => hoveredIndex = null),
                    child: GestureDetector(
                      onPanStart: (details) => _handlePanStart(index, details),
                      onPanUpdate: (details) =>
                          _handlePanUpdate(index, details),
                      onPanEnd: (details) => _handlePanEnd(index, details),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        transform: Matrix4.identity()
                          ..translate(0.0, getTranslationY(index), 0.0),
                        height: baseItemHeight,
                        width: scaledSize,
                        alignment: AlignmentDirectional.bottomCenter,
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 300),
                          scale: scale,
                          curve: Curves.easeOutCubic,
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Container(
                              height: 48,
                              width: 48,
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.primaries[
                                    items[index].icon.hashCode %
                                        Colors.primaries.length],
                              ),
                              child: Center(
                                child: items[index].icon,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ));
            }).toList()

              /// Sorts the [items] to ensure proper ordering during drag operations.
              ///
              /// This ensures the dragged [DockItem] remains visible above other [items].
              ..sort((a, b) {
                final aIndex = items.indexWhere((item) => item.key == a.key);
                final bIndex = items.indexWhere((item) => item.key == b.key);
                if (draggingIndex == aIndex) return 1;
                if (draggingIndex == bIndex) return -1;
                return 0;
              }),
          ),
        ),
      ],
    );
  }

  /// Check if the item is inside the dock using the [_dockKey].
  bool isItemInsideDock(Offset globalPosition) {
    final dockBox = _dockKey.currentContext!.findRenderObject() as RenderBox;
    final dockBounds = dockBox.localToGlobal(Offset.zero) & dockBox.size;
    return dockBounds.contains(globalPosition);
  }

  /// When the [DockItem] is being dragged.
  void _handlePanStart(int index, DragStartDetails details) {
    setState(() {
      /// Set the [draggingIndex] to the current index.
      draggingIndex = index;

      /// Find the [Dock] container.
      final dockBox = _dockKey.currentContext!.findRenderObject() as RenderBox;

      /// calculate drag [Offset] relative to the [Dock].
      dragOffset =
          items[index].position - dockBox.globalToLocal(details.globalPosition);
      isDragging = true;
    });
  }

  /// When the [DockItem] is being dragged.
  void _handlePanUpdate(int index, DragUpdateDetails details) {
    setState(() {
      final dockBox = _dockKey.currentContext!.findRenderObject() as RenderBox;
      final dockPosition = dockBox.localToGlobal(Offset.zero);
      final itemWidth = baseItemHeight + 10;

      /// Update dragged [DockItem] position
      final newPosition =
          dockBox.globalToLocal(details.globalPosition) + dragOffset;
      items[index].position = newPosition;
      final baseX = items[0].originalPosition.dx;
      final baseY = items[0].originalPosition.dy;
      // Check if item is inside dock
      if (isItemInsideDock(details.globalPosition)) {
        // Calculate target index based on position
        final relativeX = newPosition.dx - dockPosition.dx;
        int targetIndex = (relativeX / itemWidth).round();
        targetIndex = targetIndex.clamp(0, items.length - 1);

        /// Redistribute [items] normally when inside [Dock].
        for (int i = 0; i < items.length; i++) {
          if (i == index) continue;

          if (targetIndex > index) {
            if (i < index) {
              items[i].position = Offset(baseX + (i * itemWidth), baseY);
            } else if (i <= targetIndex) {
              items[i].position = Offset(baseX + ((i - 1) * itemWidth), baseY);
            } else {
              items[i].position = Offset(baseX + (i * itemWidth), baseY);
            }
          } else {
            if (i < targetIndex) {
              items[i].position = Offset(baseX + (i * itemWidth), baseY);
            } else if (i < index) {
              items[i].position = Offset(baseX + ((i + 1) * itemWidth), baseY);
            } else {
              items[i].position = Offset(baseX + (i * itemWidth), baseY);
            }
          }
        }
      } else {
        /// When dragged outside, collapse the space by shifting [items].
        for (int i = 0; i < items.length; i++) {
          if (i < index) {
            /// [items] before the dragged [DockItem] stay in place.
            items[i].position = Offset(baseX + (i * itemWidth), baseY);
          } else if (i > index) {
            /// [items] after the dragged [DockItem] shift left to fill the gap.
            items[i].position = Offset(baseX + ((i - 1) * itemWidth), baseY);
          }
        }
      }
    });
  }

  /// When the drag ends.
  void _handlePanEnd(int index, DragEndDetails details) {
    setState(() {
      if (!isItemInsideDock(details.globalPosition)) {
        /// Reset [items] to [originalPosition].
        for (int i = 0; i < items.length; i++) {
          items[i].position = items[i].originalPosition;
        }
      } else {
        /// Handle reordering inside [Dock].
        final dockBox =
            _dockKey.currentContext!.findRenderObject() as RenderBox;
        final dockStartX = dockBox.localToGlobal(Offset.zero).dx + 26;

        /// Remove and reinsert dragged [DockItem] at the new [index].
        DockItem draggedItem = items.removeAt(index);
        int newIndex = items.length;
        for (int i = 0; i < items.length; i++) {
          if (items[i].position.dx > draggedItem.position.dx) {
            newIndex = i;
            break;
          }
        }
        items.insert(newIndex, draggedItem);

        /// Update [position] and [originalPosition] of [items].
        final itemSpacing = baseItemHeight + 10;
        for (int i = 0; i < items.length; i++) {
          final newPosition = Offset(
              dockStartX + i * itemSpacing, items[0].originalPosition.dy);
          items[i].position = newPosition;
          items[i].originalPosition = newPosition;
        }
      }

      draggingIndex = null;
      isDragging = false;
      goBacktoOriginalPosition = true;
    });
  }

  /// Calculates the scaled size of the [DockItem] at the given [index].
  double getScaledSize(int index) {
    return _getPropertyValue(
      index: index,
      baseValue: baseItemHeight,
      maxValue: 70,
      nonHoveredMaximumValue: 60,
    );
  }

  /// Calculates the translation along the y-axis of the [DockItem] at the given [index].
  double getTranslationY(int index) {
    return _getPropertyValue(
      index: index,
      baseValue: baseTranslationYaxis,
      maxValue: -10,
      nonHoveredMaximumValue: -5,
    );
  }

  /// Calculates the width of the [Dock].
  double calculateDockWidth() {
    return items.fold(0.0, (totalWidth, item) {
      final index = items.indexOf(item);
      final scaledSize = getScaledSize(index);
      return totalWidth + scaledSize + 10;
    });
  }
}

class DockItem {
  /// Creates a dock item with a visual representation and identifier.
  ///
  /// The [icon] parameter defines the visual element displayed in the dock.
  /// The [label] parameter is used to generate a unique [key] for identification
  /// and must be non-null.
  DockItem({required this.icon, required this.label}) : key = ValueKey(label);

  /// The visual element displayed for this dock item.
  final Widget? icon;

  /// A descriptive label that identifies this dock item.
  ///
  /// Used to generate the [key] for equality comparison and identification.
  final String label;

  /// A unique identifier for this dock item, generated from [label].

  final Key key;

  /// The current position of the dock item in the coordinate space.
  ///
  /// Defaults to [Offset.zero] and updates during drag operations.
  Offset _position = Offset.zero;

  /// The initial position where the dock item was first placed.
  ///
  /// Used as a reference for resetting position after invalid drag operations.
  Offset _originalPosition = Offset.zero;

  /// The initial position where the dock item was first placed.
  ///
  /// This position serves as a reference point for resetting the item's
  /// location after cancelled drag operations.
  Offset get position => _position;

  /// Updates the current position of the dock item.
  ///
  /// This is typically called during drag operations to update the item's
  /// visual position in the dock.
  set position(Offset value) => _position = value;

  /// The original position of the dock item.
  ///
  /// This is the position where the item was initially placed, and is used
  /// to reset the item's position after drag operations are cancelled.
  Offset get originalPosition => _originalPosition;

  /// Updates the original position of the dock item.
  ///
  /// This should be called when initially positioning the item or after
  /// a successful reordering operation.
  set originalPosition(Offset value) => _originalPosition = value;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DockItem && other.key == key;
  }

  @override
  int get hashCode => key.hashCode;
}
