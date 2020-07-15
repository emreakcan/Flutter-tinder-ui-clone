import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fluttery_dart2/layout.dart';
import 'package:hookups/scr/matches.dart';

enum SlideDirection { left, right, up }
enum SlideRegion { inNopeRegion, inLikeRegion, inSuperLikeRegion }
class DraggableCard extends StatefulWidget {
  final Widget card;
  final SlideDirection slideTo;
  final SlideRegion slideRegion;
  final Function(double distance) onSlideUpdate;
  final Function(SlideRegion slideRegion) onSlideRegionUpdate;
  final Function(SlideDirection direction) onSlideOutComplete;
  final bool isDraggable;
  DraggableCard(
      {this.card,
      this.isDraggable = true,
      this.onSlideUpdate,
      this.onSlideOutComplete,
      this.slideTo,
      this.slideRegion,
      this.onSlideRegionUpdate});
  @override
  _DraggableCardState createState() => _DraggableCardState(isDraggable);
}

class _DraggableCardState extends State<DraggableCard>
    with TickerProviderStateMixin {
  Decision decision;
  GlobalKey profileCardKey = new GlobalKey(debugLabel: 'profile_card_key');
  Offset cardOffset = const Offset(0.0, 0.0);
  Offset dragStart;
  Offset dragPosition;
  Offset slideBackStart;
  SlideDirection slideOutDirection;
  SlideRegion slideRegion;
  AnimationController slideBackAnimation;
  Tween<Offset> slideOutTween;
  AnimationController slideOutAnimation;
  bool isDraggable;
  _DraggableCardState(this.isDraggable);

  @override
  void initState() {
    super.initState();
    print(isDraggable);
    slideBackAnimation = new AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )
      ..addListener(() => setState(() {
            cardOffset = Offset.lerp(
              slideBackStart,
              const Offset(0.0, 0.0),
              Curves.elasticOut.transform(slideBackAnimation.value),
            );


            if (null != widget.onSlideUpdate) {
              widget.onSlideUpdate(cardOffset.distance);
            }

            if (null != widget.onSlideRegionUpdate) {
              widget.onSlideRegionUpdate(slideRegion);
            }
          }))
      ..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            dragStart = null;
            slideBackStart = null;
            dragPosition = null;
          });
        }
      });

    slideOutAnimation = new AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )
      ..addListener(() {
        setState(() {
          cardOffset = slideOutTween.evaluate(slideOutAnimation);

          if (null != widget.onSlideUpdate) {
            widget.onSlideUpdate(cardOffset.distance);
          }

          if (null != widget.onSlideRegionUpdate) {
            widget.onSlideRegionUpdate(slideRegion);
          }
        });
      })
      ..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            dragStart = null;
            dragPosition = null;
            slideOutTween = null;

            if (widget.onSlideOutComplete != null) {
              widget.onSlideOutComplete(slideOutDirection);
            }
          });
        }
      });
  }

  @override
  void didUpdateWidget(DraggableCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.card.key != oldWidget.card.key) {
      cardOffset = const Offset(0.0, 0.0);
    }

    if (oldWidget.slideTo == null && widget.slideTo != null) {
      switch (widget.slideTo) {
        case SlideDirection.left:
          _slideLeft();
          break;
        case SlideDirection.right:
          _slideRight();
          break;
        case SlideDirection.up:
          _slideUp();
          break;
      }
    }

  }

  @override
  void dispose() {
    slideBackAnimation.dispose();
    super.dispose();
  }

  Offset _chooseRandomDragStart() {
    final cardContext = profileCardKey.currentContext;
    final cardTopLeft = (cardContext.findRenderObject() as RenderBox)
        .localToGlobal(const Offset(0.0, 0.0));
    final dragStartY = cardContext.size.height *
            (new Random().nextDouble() < 0.5 ? 0.25 : 0.75) +
        cardTopLeft.dy;
    return new Offset(cardContext.size.width / 2 + cardTopLeft.dx, dragStartY);
  }

  void _slideLeft() async {
    await Future.delayed(Duration(milliseconds: 1)).then((_) {
      final screenWidth = context.size.width;
      dragStart = _chooseRandomDragStart();
      slideOutTween = new Tween(
          begin: const Offset(0.0, 0.0),
          end: new Offset(-2 * screenWidth, 0.0));
      slideOutAnimation.forward(from: 0.0);
    });
  }

  void _slideRight() async {
    await Future.delayed(Duration(milliseconds: 1)).then((_) {
      final screenWidth = context.size.width;
      dragStart = _chooseRandomDragStart();
      slideOutTween = new Tween(
          begin: const Offset(0.0, 0.0), end: new Offset(2 * screenWidth, 0.0));
      slideOutAnimation.forward(from: 0.0);
    });
  }

  void _slideUp() async {
    await Future.delayed(Duration(milliseconds: 1)).then((_) {
      final screenHeight = context.size.height;
      dragStart = _chooseRandomDragStart();
      slideOutTween = new Tween(
          begin: const Offset(0.0, 0.0),
          end: new Offset(0.0, -2 * screenHeight));
      slideOutAnimation.forward(from: 0.0);
    });
  }

  void _onPanStart(DragStartDetails details) {
    if(!isDraggable)
      return;

    print("onPanStart");
    dragStart = details.globalPosition;

    if (slideBackAnimation.isAnimating) {
      slideBackAnimation.stop(canceled: true);
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    print("UPDATE");

    final isInLeftRegion = (cardOffset.dx / context.size.width) < -0.45;
    final isInRightRegion = (cardOffset.dx / context.size.width) > 0.45;
    final isInTopRegion = (cardOffset.dy / context.size.height) < -0.40;

    setState(() {
      if (isInLeftRegion || isInRightRegion) {
        slideRegion = isInLeftRegion
            ? SlideRegion.inNopeRegion
            : SlideRegion.inLikeRegion;
      } else if (isInTopRegion) {
        slideRegion = SlideRegion.inSuperLikeRegion;
      } else {
        slideRegion = null;
      }

      dragPosition = details.globalPosition;
      cardOffset = dragPosition - dragStart;

      if (null != widget.onSlideUpdate) {
        widget.onSlideUpdate(cardOffset.distance);
      }

      if (null != widget.onSlideRegionUpdate) {
        widget.onSlideRegionUpdate(slideRegion);
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final dragVector = cardOffset / cardOffset.distance;
    print((cardOffset.dx / context.size.width));

    final isInLeftRegion = (cardOffset.dx / context.size.width) < -0.15;
    final isInRightRegion = (cardOffset.dx / context.size.width) > 0.15;
    final isInTopRegion = (cardOffset.dy / context.size.height) < -0.10;
    print("isInLeft $isInLeftRegion");
    print("isInRightRegion $isInRightRegion");
    print("isInTopRegion $isInTopRegion");

    setState(() {
      if (isInLeftRegion || isInRightRegion) {
        slideOutTween = new Tween(
            begin: cardOffset, end: dragVector * (2 * context.size.width));
        slideOutAnimation.forward(from: 0.0);

        slideOutDirection =
            isInLeftRegion ? SlideDirection.left : SlideDirection.right;
      } else if (isInTopRegion) {
        slideOutTween = new Tween(
            begin: cardOffset, end: dragVector * (2 * context.size.height));
        slideOutAnimation.forward(from: 0.0);

        slideOutDirection = SlideDirection.up;
      } else {
        slideBackStart = cardOffset;
        slideBackAnimation.forward(from: 0.0);
      }

      slideRegion = null;
      if (null != widget.onSlideRegionUpdate) {
        widget.onSlideRegionUpdate(slideRegion);
      }
    });

  }

  double _rotation(Rect dragBounds) {
    if (dragStart != null) {
      final rotationCornerMultiplier =
          dragStart.dy >= dragBounds.top + (dragBounds.height / 2) ? -1 : 1;
      return (pi / 8) *
          (cardOffset.dx / dragBounds.width) *
          rotationCornerMultiplier;
    } else {
      return 0.0;
    }
  }

  Offset _rotationOrigin(Rect dragBounds) {
    if (dragStart != null) {
      return dragStart - dragBounds.topLeft;
    } else {
      return const Offset(0.0, 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return new AnchoredOverlay(
      showOverlay: true,
      child: new Center(),
      overlayBuilder: (BuildContext context, Rect anchorBounds, Offset anchor) {
        return CenterAbout(
          position: anchor,
          child: new Transform(
            transform: new Matrix4.translationValues(cardOffset.dx, cardOffset.dy, 0.0)..rotateZ(_rotation(anchorBounds)),
            origin: _rotationOrigin(anchorBounds),
            child: new Container(
              key: profileCardKey,
              width: anchorBounds.width,
              height: anchorBounds.height,
              padding: const EdgeInsets.all(16.0),
              child: new GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: widget.card,
              ),
            ),
          ),
        );
      },
    );
  }
}
