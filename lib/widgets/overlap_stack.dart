import 'package:flutter/material.dart';

/*
 * @Description 七个牌堆以及左面的翻开的牌堆中反面朝上的牌堆
 * @Since version-1.0
 */

class OverlapStack extends StatelessWidget {
  OverlapStack(
      {Key? key,
      required List<Widget> children,
      this.childrenOffset = _defaultOffset})
      : itemCount = children.length,
        itemBuilder = ((context, index) => children[index]),
        super(key: key);

  const OverlapStack.builder(
      {Key? key,
      required this.itemBuilder,
      required this.itemCount,
      this.childrenOffset = _defaultOffset})
      : super(key: key);

  static const _defaultOffset = Offset(128, 0);
  final Offset childrenOffset;
  final IndexedWidgetBuilder itemBuilder;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    List<Widget> children =
        List.generate(itemCount, (index) => itemBuilder(context, index));
    List<Widget> _childrenSortedByZIndex = List.from(children)
      ..sort((child, otherChild) => child.zIndex.compareTo(otherChild.zIndex));
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (Widget child in _childrenSortedByZIndex) ...{
          Container(
            padding: EdgeInsets.only(
              left: children.indexOf(child) * childrenOffset.dx,
              top: children.indexOf(child) * childrenOffset.dy,
            ),
            child: child,
          ),
        }
      ],
    );
  }
}

/*
 * @Description 牌堆中的每一个item
 * @Since version-1.0
 */

class OverlapStackItem extends StatelessWidget {
  const OverlapStackItem({
    Key? key,
    required this.child,
    required this.zIndex,
  }) : super(key: key);

  final Widget child;
  final int zIndex;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

extension on Widget {
  int get zIndex {
    return this is OverlapStackItem ? (this as OverlapStackItem).zIndex : 0;
  }
}
