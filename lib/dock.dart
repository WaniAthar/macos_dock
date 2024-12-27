import 'dart:ui';
import 'package:flutter/material.dart';

/// Main class for the dock (root widget)
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: DockDemo(),
    );
  }
}

/// DockDemo is the screen widget for the dock.
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

/// DockItem is a model class for the dock items
/// [icon] is the icon of the item
/// [label] is the label for the item if any
/// [key] is a ValueKey for the item, used for uniquely identifying the item
/// [position] is the current position of the item
/// [originalPosition] is the original position of the item, used for resetting the item position
class DockItem {
  final Widget? icon;
  final String label;
  final Key key;
  Offset _position = Offset.zero;
  Offset _originalPosition = Offset.zero;

  DockItem({required this.icon, required this.label}) : key = ValueKey(label);

  /// getter for obtaining the position of the item
  Offset get position => _position;

  /// setter for setting the position of the item
  set position(Offset value) => _position = value;

  /// getter for obtaining the original position of the item
  Offset get originalPosition => _originalPosition;

  /// setter for resetting the original position of the item
  set originalPosition(Offset value) => _originalPosition = value;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DockItem && other.key == key;
  }

  @override
  int get hashCode => key.hashCode;
}

/// Dock is the stateful widget for the dock inside which all the DockItems are placed
class Dock extends StatefulWidget {
  const Dock({super.key});

  @override
  State<Dock> createState() => _DockState();
}

/// _DockState is the state class for the dock for maintaining the state of the dockItems and the dock
class _DockState extends State<Dock> {
  ///[hoveredIndex] is the index of the hovered item
  late int? hoveredIndex;

  ///[baseItemHeight] is the base height of the dockItems
  late double baseItemHeight;

  ///[baseTranslationYaxis] is the base translation of the dockItems along the positive y-axis
  late double baseTranslationYaxis;

  ///[verticleItemsPadding] is the padding between the dockItems
  late double verticleItemsPadding;

  ///[items] is the list of dockItems which will be placed inside the dock
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

  ///[dockKey] is the key for the dock in order to check the bounds of the dock
  final GlobalKey _dockKey = GlobalKey();

  ///[emptyIndex] is the index of the dummy item in the items list
  int? emptyIndex;

  /// [isDragging] is a boolean flag to check if the dock is currently being dragged or not.
  bool isDragging = false;

  ///[dragOffset] is the offset of the drag, used to calculate the new position of the dragged item, defaulted to zero
  Offset dragOffset = Offset.zero;

  ///[goBacktoOriginalPosition] is a boolean flag to check if the dragged item should go back to its original position or not.
  bool goBacktoOriginalPosition = false;

  ///[draggingIndex] is the index of the item being dragged
  int? draggingIndex;

  ///[_getPropertyValue] is a method used to calculate two properties of the dockItems i.e the scaled size and the translation along the y-axis
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

    /// [itemsAffected] is the number of items affected by the hover
    final itemsAffected = items.length;

    /// if the difference is zero then the property value is the maximum value because it will be the hovered item
    /// else if the difference is less than the number of items affected by the hover, items that are closer to the hoveredIndex will have slightly greater value than those that are far.
    /// else the property value is the base value because it will be the item that is not affected by the hover
    if (difference == 0) {
      propertyValue = maxValue;
    } else if (difference <= itemsAffected) {
      final ratio = (itemsAffected - difference) / itemsAffected;
      propertyValue = lerpDouble(baseValue, nonHoveredMaximumValue, ratio)!;
    } else {
      propertyValue = baseValue;
    }
    return propertyValue;
  }

  @override
  Widget build(BuildContext context) {
    /// calculate the dock width based on the items
    final dockWidth = calculateDockWidth();
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: AnimatedContainer(
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

                /// AnimatedPositioned used for animating the dockItems while draggind and reordering
                return AnimatedPositioned(
                    duration: Duration(
                        milliseconds: goBacktoOriginalPosition &&
                                draggingIndex != index

                            /// if the item is being dragged and the goBacktoOriginalPosition is true, then the dock item will animate else it will move along with the dragging cursor
                            ? 300
                            : 0),
                    key: items[index].key,
                    left: itemPosition.dx,
                    top: itemPosition.dy,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.grab,
                      onEnter: (event) => setState(() => hoveredIndex = index),
                      onExit: (event) => setState(() => hoveredIndex = null),
                      child: GestureDetector(
                        onPanStart: (details) =>
                            _handlePanStart(index, details),
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

                /// sort the items based on the dragging index, so that the dragged item is always on top and not being overlapped by other items while dragging
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
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    /// initialize the hovered index to null
    hoveredIndex = null;

    /// initialize the base item height to 50
    baseItemHeight = 50;

    /// initialize the base translation to 0
    baseTranslationYaxis = 0.0;

    /// initialize the padding between the items to 10
    verticleItemsPadding = 10;

    // calculate starting positions centered on screen after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;
      final itemSpacing = 10;

      final totalWidth = items.length * (baseItemHeight + itemSpacing);
      final startX = ((screenWidth - totalWidth) / 2) + 4;
      final centerY = (screenHeight / 2) - 42;

      // initialize item positions in a horizontal row inside the dock container
      for (int i = 0; i < items.length; i++) {
        items[i].position =
            Offset(startX + (i * (baseItemHeight + itemSpacing)), centerY);
        items[i].originalPosition = items[i].position;
      }
      setState(() {});
    });
  }

  /// method to check if the item is inside the dock sing [_dockKey] global key
  bool isItemInsideDock(Offset globalPosition) {
    final dockBox = _dockKey.currentContext!.findRenderObject() as RenderBox;
    final dockBounds = dockBox.localToGlobal(Offset.zero) & dockBox.size;
    return dockBounds.contains(globalPosition);
  }

  /// this method is called when the item has started to be dragged
  void _handlePanStart(int index, DragStartDetails details) {
    setState(() {
      /// set the dragging index to the current index
      draggingIndex = index;

      /// find the dock container
      final dockBox = _dockKey.currentContext!.findRenderObject() as RenderBox;

      // calculate drag offset relative to the dock container
      dragOffset =
          items[index].position - dockBox.globalToLocal(details.globalPosition);
      isDragging = true;
    });
  }

  /// this method is called when the item is being dragged
  void _handlePanUpdate(int index, DragUpdateDetails details) {
    setState(() {
      final dockBox = _dockKey.currentContext!.findRenderObject() as RenderBox;
      final dockPosition = dockBox.localToGlobal(Offset.zero);
      final itemWidth = baseItemHeight + 10; // Consistent spacing

      /// update dragged item position
      final newPosition =
          dockBox.globalToLocal(details.globalPosition) + dragOffset;
      items[index].position = newPosition;

      /// check if the item is inside the dock and perform the reordering
      if (isItemInsideDock(details.globalPosition)) {
        /// calculate the ideal position for the dragged item
        final relativeX = newPosition.dx - dockPosition.dx;
        int targetIndex = (relativeX / itemWidth).round();
        targetIndex = targetIndex.clamp(0, items.length - 1);

        /// calculate base position (left most item's position)
        final baseX = items[0].originalPosition.dx;
        final baseY = items[0].originalPosition.dy;

        /// redistribute items based on the dragged item's position
        for (int i = 0; i < items.length; i++) {
          if (i == index) continue; // Skip dragged item

          if (targetIndex > index) {
            /// when dragging right
            if (i < index) {
              /// items before dragged item stay in place
              items[i].position = Offset(baseX + (i * itemWidth), baseY);
            } else if (i <= targetIndex) {
              /// items between original and target move to left
              items[i].position = Offset(baseX + ((i - 1) * itemWidth), baseY);
            } else {
              /// items after target stay in place
              items[i].position = Offset(baseX + (i * itemWidth), baseY);
            }
          } else {
            /// dragging left
            if (i < targetIndex) {
              /// items before target stay in place
              items[i].position = Offset(baseX + (i * itemWidth), baseY);
            } else if (i < index) {
              /// items between target and original move right
              items[i].position = Offset(baseX + ((i + 1) * itemWidth), baseY);
            } else {
              /// items after dragged item stay in place
              items[i].position = Offset(baseX + (i * itemWidth), baseY);
            }
          }
        }
      } else {
        // reset positions when dragged outside,
        for (int i = 0; i < items.length; i++) {
          if (i != index) {
            items[i].position = items[i].originalPosition;
          }
        }
      }
    });
  }

  /// this method is called when the drag ends
  void _handlePanEnd(int index, DragEndDetails details) {
    setState(() {
      final dockBox = _dockKey.currentContext!.findRenderObject() as RenderBox;
      final dockStartX = dockBox.localToGlobal(Offset.zero).dx +
          26; // Include offset adjustment

      if (!isItemInsideDock(details.globalPosition)) {
        // If item is outside dock, reset it to its original position
        items[index].position = items[index].originalPosition;
        goBacktoOriginalPosition = true;
      } else {
        // Remove the dragged item from the list
        DockItem draggedItem = items.removeAt(index);

        // Find the new index based on the dragged item's position
        int newIndex = items.length; // Default to the end
        for (int i = 0; i < items.length; i++) {
          if (items[i].position.dx > draggedItem.position.dx) {
            newIndex = i;
            break;
          }
        }

        // Insert the dragged item at the calculated position
        items.insert(newIndex, draggedItem);

        // Recalculate positions for all items
        final itemSpacing = baseItemHeight + 10; // Ensure consistent spacing
        for (int i = 0; i < items.length; i++) {
          items[i].position = Offset(
            dockStartX + i * itemSpacing, // Calculate new position
            items[0].originalPosition.dy, // Maintain vertical alignment
          );
          items[i].originalPosition = items[i].position;
          goBacktoOriginalPosition = true;
        }
      }

      draggingIndex = null;
      isDragging = false;
    });
  }

  ///[_getScaledSize] is a method to calculate the scaled size of the dockItems
  double getScaledSize(int index) {
    return _getPropertyValue(
      index: index,
      baseValue: baseItemHeight,
      maxValue: 70,
      nonHoveredMaximumValue: 60,
    );
  }

  ///[_getTranslationY] is a method to calculate the translation along the y axis of the dockItems
  double getTranslationY(int index) {
    return _getPropertyValue(
      index: index,
      baseValue: baseTranslationYaxis,
      maxValue: -10,
      nonHoveredMaximumValue: -5,
    );
  }

  ///[calculateDockWidth] is a method to calculate the width of the dock
  double calculateDockWidth() {
    return items.fold(0.0, (totalWidth, item) {
      final index = items.indexOf(item);
      final scaledSize = getScaledSize(index);
      return totalWidth + scaledSize + 10;
    });
  }
}
