import 'dart:math';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:quards/main.dart';

typedef ElevationWidgetBuilder = Widget Function(BuildContext context,
    Widget? child, double elevation, bool isDragged, double scale);

/*
 * @Date  4.1
 * @Description 能拖动、能执行自动复位动画的卡片类
 * @Since version-1.0
 */

class DraggableCard<T extends Object> extends StatefulWidget {
  const DraggableCard(
      {Key? key,
      this.child,
      this.builder = defaultBuilder,
      this.elevation = 0,
      this.hoverElevation = 16.0,
      this.onHover,
      this.onDragStart,
      this.onDragCancel,
      this.onDragAccept,
      this.onDragReturn,
      this.onDoubleTap,
      this.data,
      this.forceHovering,
      this.releasedNotifier,
      this.shouldUpdateOnRelease,
      this.canDrag = true,
      this.canHover = true})
      : super(key: key);

  final Widget? child;
  final double hoverElevation;
  final double elevation;
  final ElevationWidgetBuilder builder;
  final ValueChanged<bool>? onHover;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragCancel;
  final ValueChanged<Offset>? onDragAccept;
  final VoidCallback? onDragReturn;
  final VoidCallback? onDoubleTap;
  final T? data;
  final bool? forceHovering;
  final bool canDrag;
  final bool canHover;
  final ValueNotifier<HoverReleaseDetails?>? releasedNotifier;
  final bool Function(HoverReleaseDetails?)? shouldUpdateOnRelease;

  static Widget defaultBuilder(BuildContext context, Widget? child,
      double elevation, bool isDragged, double scale) {
    return child ?? Container();
  }

  @override
  _DraggableCardState createState() => _DraggableCardState();
}

class _DraggableCardState<T extends Object> extends State<DraggableCard<T>>
    with TickerProviderStateMixin {
  final double maxRotationDegrees = 15;
  final double maxVelocity = 2500;
  double get maxRotation => maxRotationDegrees / 180 * pi;

  final GlobalKey _gestureDetectorKey = GlobalKey();

  late final AnimationController hoverAnimationController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 250));

  late final Animation hoverAnimation = CurvedAnimation(
      parent: hoverAnimationController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic);

  late final AnimationController offsetAnimationController =
      AnimationController(
          vsync: this, duration: const Duration(milliseconds: 300));

  late final Animation offsetAnimation = CurvedAnimation(
      parent: offsetAnimationController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic);

  Offset draggableReleasedOffset = Offset.zero;

  double get hoverPercentage => hoverAnimation.value;
  double get elevation => lerpDouble(
      widget.elevation, widget.hoverElevation, hoverAnimation.value)!;

  double get scale => lerpDouble(1, hoveredScale, hoverPercentage)!;
  double hoveredScale = 1.1;

  bool isDragging = false;
  bool _isHovering = false;

  bool get isHovering => _isHovering;

  bool hasUpdated = false;

  set isHovering(bool isHovering) {
    _isHovering = isHovering;
    if (widget.onHover != null) widget.onHover!(isHovering);
    if (isHovering) {
      hoverAnimationController.forward();
    } else {
      hoverAnimationController.reverse();
    }
  }

  void releasedNotifierCallback() async {
    final HoverReleaseDetails? details = widget.releasedNotifier?.value;
    if (details != null) {
      final shouldUpdate = widget.shouldUpdateOnRelease != null
          ? widget.shouldUpdateOnRelease!(details)
          : true;

      if (shouldUpdate) {
        await springBackFrom(details.offset);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    hasUpdated = true;
    final HoverReleaseDetails? details = widget.releasedNotifier?.value;
    final shouldUpdate = widget.shouldUpdateOnRelease != null
        ? widget.shouldUpdateOnRelease!(details)
        : true;
    if (shouldUpdate) {
      releasedNotifierCallback();
    }
    releasedNotifierCallback();
    WidgetsBinding.instance!.scheduleFrameCallback((timeStamp) {
      releasedNotifierCallback();
    });
    widget.releasedNotifier?.addListener(releasedNotifierCallback);
  }

  @override
  void dispose() {
    widget.releasedNotifier?.removeListener(releasedNotifierCallback);
    offsetAnimationController.dispose();
    hoverAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.forceHovering != null) {
      if (widget.forceHovering! != isHovering) {
        if (widget.forceHovering!) {
          hoverAnimationController.forward();
        } else {
          hoverAnimationController.reverse();
        }
      }
    } else {
      if (isHovering) {
        hoverAnimationController.forward();
      } else {
        hoverAnimationController.reverse();
      }
    }
    return Opacity(
      opacity: hasUpdated ? 1 : 0,
      child: GestureDetector(
        onDoubleTap: widget.onDoubleTap,
        child: Listener(
          onPointerDown: (event) {
            isHovering = true;
          },
          onPointerUp: (event) {
            if (event.kind != PointerDeviceKind.mouse) isHovering = false;
          },
          onPointerCancel: (event) {
            isHovering = false;
          },
          child: MouseRegion(
            onEnter: (event) {
              if (!event.down) {
                isHovering = widget.canHover;
              }
            },
            onExit: (PointerExitEvent event) {
              isHovering = false;
            },
            child: Draggable<T>(
              key: _gestureDetectorKey,
              maxSimultaneousDrags: widget.canDrag ? null : 0,
              data: widget.data,
              feedback: Transform.scale(
                      scale: hoveredScale,
                      child: widget.builder(
                          context, widget.child, elevation, true, scale)),
              onDragStarted: () {
                isHovering = true;
                if (widget.onDragStart != null) widget.onDragStart!();
              },
              onDragEnd: (DraggableDetails details) {
                if (details.wasAccepted) {
                  if (widget.onDragAccept != null) {
                    widget.onDragAccept!(details.offset);
                  }
                }
              },
              onDraggableCanceled: (velocity, offset) {
                if (widget.onDragCancel != null) widget.onDragCancel!();
                springBackFrom(offset);
              },
              childWhenDragging: Opacity(
                opacity: 0,
                child: widget.builder(context, widget.child, 0, false, scale),
              ),
              child: AnimatedBuilder(
                animation: offsetAnimation,
                builder: (context, child) {
                  final offsetScale = offsetAnimation.value;
                  return Transform.translate(
                      offset: draggableReleasedOffset.scale(
                          offsetScale, offsetScale),
                      child: child);
                },
                child: AnimatedBuilder(
                  animation: hoverAnimation,
                  builder: (context, child) {
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: widget.builder(context, widget.child, elevation,
                      offsetAnimation.value != 0, scale),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> springBackFrom(Offset offset) async {
    if (_gestureDetectorKey.currentContext?.findRenderObject() == null) {
      return;
    }
    RenderBox box =
        _gestureDetectorKey.currentContext!.findRenderObject() as RenderBox;
    draggableReleasedOffset = box.globalToLocal(offset);
    final double longestScreenSide = MediaQuery.of(context).size.longestSide;

    final durationPercentage = Curves.easeOutCubic
        .transform(draggableReleasedOffset.distance / longestScreenSide)
        .clamp(0.5, 1);
    offsetAnimationController.duration =
        Duration(milliseconds: (durationPercentage * 400).toInt());
    offsetAnimationController.value = 1;
    offsetAnimationController
        .reverse()
        .whenComplete(widget.onDragReturn ?? () {});
    return hoverAnimationController.reverse();
  }
}
