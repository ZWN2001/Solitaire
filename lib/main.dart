import 'dart:collection';
import 'dart:math';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quards/models/deck.dart';
import 'package:quards/models/games/solitaire/card.dart';
import 'package:quards/models/games/solitaire/moves.dart';
import 'package:quards/models/games/solitaire/solitaire.dart';
import 'package:quards/models/shortcuts/intents.dart';

import 'models/games/solitaire/pile.dart';
import 'widgets/draggable_card.dart';
import 'widgets/overlap_stack.dart';
import 'widgets/poker_card.dart';

void main() {
  runApp(Quards());
  doWhenWindowReady(() {
    appWindow.title = "Quards Solitaire";
    const initialSize = Size(1200, 700);
    appWindow.minSize = initialSize;
    appWindow.size = initialSize;
    appWindow.alignment = Alignment.center;
    appWindow.show();
  });
}

class Quards extends StatelessWidget {
  Quards({Key? key}) : super(key: key);

  final ThemeData data = ThemeData(
    brightness: Brightness.dark,
    cardColor: const Color(0xFF3F4950),
    scaffoldBackgroundColor: const Color(0xFF2D3439),
    primarySwatch: Colors.blue,
    primaryColor: Colors.green,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'quards - solitaire',
      theme: data.copyWith(textTheme: GoogleFonts.alataTextTheme(data.textTheme)),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class HoverReleaseDetails {
  const HoverReleaseDetails(
      {required this.card, required this.acceptedPile, required this.offset});
  //牌
  final StandardCard card;
  final Offset offset;
  //接受前的牌堆
  final SolitairePile acceptedPile;
}

class _MainPageState extends State<MainPage>
    with SingleTickerProviderStateMixin {
  SolitaireGame game = SolitaireGame();
  SolitaireCardLocation? hoveredLocation;
  SolitaireCardLocation? draggedLocation;
  Map<StandardCard, SolitaireCardLocation?> releasedCardOrigin = {};
  Map<StandardCard, SolitaireCardLocation?> releasedCardDestination = {};
  ValueNotifier<HoverReleaseDetails?> releasedNotifier = ValueNotifier(null);
  SolitairePile? hoveredPile;
  Set<SolitaireCard> animatingCards = HashSet();
  late Map<Pile, GlobalKey> pileKeys = {
    for (Pile pile in game.allPiles) pile: GlobalKey()
  };

  double get screenUnit => calculateScreenUnit();
  double get gutterWidth => screenUnit * 2;
  double get cardWidth => screenUnit * 10;
  Offset get tableauCardOffset => Offset(0, screenUnit * 4);
  Offset get wasteCardOffset => const Offset(0, 0);

  late final AnimationController winAnimationController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1000));
  late final winFadeAnimation = CurvedAnimation(
      parent: winAnimationController,
      curve: const Interval(0, 0.5),
      reverseCurve: const Interval(0.5, 1));
  late final winTextAnimation = CurvedAnimation(
      parent: winAnimationController,
      curve: const Interval(0.5, 1, curve: Curves.elasticOut),
      reverseCurve: const Interval(0, 0));

  @override
  void initState() {
    super.initState();
    game.won.addListener(onGameWinUpdate);
  }

  //完成时展示动画
  void onGameWinUpdate() {
    if (game.won.value) {
      winAnimationController.forward(from: 0);
    }
  }

  double calculateScreenUnit() {
    final double screenWidth = MediaQuery.of(context).size.width;
    const double gutterScreenUnits = 2;
    const double cardWidthScreenUnits = 10;
    const totalScreenUnits = gutterScreenUnits * 13 + cardWidthScreenUnits * 9;
    final double screenUnitFromWidth = (screenWidth - 104) / totalScreenUnits;

    final double screenHeight = MediaQuery.of(context).size.height;
    const totalScreenUnitsHeight =
        5 * gutterScreenUnits + 4 * cardWidthScreenUnits * (5 / 3);
    final double screenUnitFromHeight = screenHeight / totalScreenUnitsHeight;
    return min(screenUnitFromWidth, screenUnitFromHeight);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildShortcuts(
        child: Center(
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Stack(
                alignment: Alignment.bottomLeft,
                children: [
                  Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              //左下角正方形
                              Transform.rotate(
                                angle: pi / 4,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  height: Theme.of(context)
                                      .textTheme
                                      .headline2!
                                      .fontSize,
                                  width: Theme.of(context)
                                      .textTheme
                                      .headline2!
                                      .fontSize,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: _buildAppName(),
                              ),
                            ],
                          ),
                          Text(
                            'Solitaire',
                            style:
                            Theme.of(context).textTheme.headline4?.copyWith(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.only(top: gutterWidth),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 64.0,
                          child: Column(
                            children: [
                              IconButton(
                                tooltip: '新游戏 (R)',
                                onPressed: () {
                                  setState(() {
                                    startNewGame(context);
                                  });
                                },
                                icon: const Icon(Icons.refresh),
                              ),
                              const Divider(),
                              IconButton(
                                tooltip: '撤销 (Ctrl-Z)',
                                onPressed: game.canUndo()
                                    ? () {
                                        undoPreviousMove();
                                      }
                                    : null,
                                icon: const Icon(Icons.undo),
                              ),
                              IconButton(
                                tooltip: '重做 (Ctrl-Shift Z/Ctrl-Y)',
                                onPressed: game.canRedo()
                                    ? () {
                                        redoPreviousMove();
                                      }
                                    : null,
                                icon: const Icon(Icons.redo),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildStockPile(game.stock.stockPile),
                            SizedBox(height: gutterWidth),
                            _buildPile(game.stock.wastePile,
                                verticalCardOffset: wasteCardOffset),
                          ],
                        ),
                        SizedBox(width: gutterWidth),
                        // 七个牌堆
                        for (SolitairePile pile in game.tableauPiles) ...{
                          _buildPile(pile, halfGutters: true),
                        },
                        SizedBox(width: gutterWidth),
                        IconButton(
                          onPressed: game.canAutoMove()
                              ? () {
                                  setState(() {
                                    game.makeAllPossibleFoundationMoves();
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.arrow_right_alt),
                          tooltip: '自动移入suitpiles (Space)',
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (SolitairePile foundation in game.foundations) ...{
                              _buildPile(foundation,
                                  verticalCardOffset: Offset.zero),
                              SizedBox(height: gutterWidth),
                            },
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              IgnorePointer(
                ignoring: !game.won.value,
                child: FadeTransition(
                  opacity: winFadeAnimation,
                  child: Container(
                    color: Colors.black.withOpacity(0.75),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedBuilder(
                            animation: winTextAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: winTextAnimation.value,
                                child: child,
                              );
                            },
                            child: Text(
                              '恭喜你赢了游戏!',
                              style: Theme.of(context).textTheme.headline3,
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                startNewGame(context);
                              });
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('新游戏'),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //绘制左下角标志
  Widget _buildAppName() {
    return Stack(
      children: [
        Text(
          'quards',
          style: Theme.of(context).textTheme.headline2?.copyWith(
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 8
                  ..color = Theme.of(context).scaffoldBackgroundColor,
              ),
        ),
        Text(
          'quards',
          style: Theme.of(context).textTheme.headline2?.copyWith(
                color: Color.lerp(Theme.of(context).hintColor,
                    Theme.of(context).scaffoldBackgroundColor, 0.9),
              ),
        ),
      ],
    );
  }

  //绑定快捷键
  Widget _buildShortcuts({required Widget child}) {
    bool canUseShortcut = draggedLocation == null;
    return Shortcuts(
        shortcuts: {
          LogicalKeySet(LogicalKeyboardKey.keyR): const NewGameIntent(),
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ):
              const UndoIntent(),
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyY):
              const RedoIntent(),
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift,
              LogicalKeyboardKey.keyZ): const RedoIntent(),
          LogicalKeySet(LogicalKeyboardKey.space):
              const MoveCardsToFoundationIntent(),
          // LogicalKeySet(LogicalKeyboardKey.keyD): const DrawFromStockIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            UndoIntent: CallbackAction<UndoIntent>(
              onInvoke: (UndoIntent intent) {
                if (canUseShortcut) {
                  setState(() {
                    if (game.canUndo()) undoPreviousMove();
                  });
                }
                return null;
              },
            ),
            RedoIntent: CallbackAction<RedoIntent>(
              onInvoke: (RedoIntent intent) {
                if (canUseShortcut) {
                  setState(() {
                    if (game.canRedo()) redoPreviousMove();
                  });
                }
                return null;
              },
            ),
            NewGameIntent: CallbackAction<NewGameIntent>(
              onInvoke: (NewGameIntent intent) {
                if (canUseShortcut) {
                  setState(() {
                    startNewGame(context);
                  });
                }
                return null;
              },
            ),
            MoveCardsToFoundationIntent:
                CallbackAction<MoveCardsToFoundationIntent>(
              onInvoke: (MoveCardsToFoundationIntent intent) {
                if (canUseShortcut) {
                  setState(() {
                    game.makeAllPossibleFoundationMoves();
                  });
                }
                return null;
              },
            ),
            // DrawFromStockIntent: CallbackAction<DrawFromStockIntent>(
            //     onInvoke: (DrawFromStockIntent intent) {
            //   if (canUseShortcut) {
            //     setState(() {
            //       drawFromStockPile();
            //     });
            //   }
            //   return null;
            // }),
          },
          child: Focus(
            autofocus: true,
            child: child,
          ),
        ));
  }

  Widget _buildCard(SolitaireCard card, SolitaireCardLocation location) {
    //draggedLocation 为空说明就没有被拖拽
    final bool isDraggedByAnotherCard = draggedLocation != null
        ? location.pile == draggedLocation!.pile &&
            location.row >= draggedLocation!.row
        : false;
    final bool isReturning = animatingCards.contains(card);
    final bool isRenderedByAnotherCard = isDraggedByAnotherCard || isReturning;
    return OverlapStackItem(
      zIndex: 1,
      child: DraggableCard<SolitaireCardLocation>(
        elevation: 10.0,
        hoverElevation: 10.0,
        data: location,
        forceHovering: hoveredLocation != null
            ? location.pile == hoveredLocation!.pile &&
                location.row >= hoveredLocation!.row
            : null,
        onDoubleTap: () {
          tryMoveToFoundation(card, location);
        },
        onHover: (bool hovered) {
          if (hovered) {
            if(mounted){
              setState(() {
                hoveredLocation = location;
              });
            }
          } else {
            if(mounted) {
              setState(() {
                hoveredLocation = null;
              });
            }
          }
        },
        onDragStart: () {
          setState(() {
            draggedLocation = location;
          });
        },
        onDragCancel: () {
          setState(() {
            draggedLocation = null;
            // Add every card below this
            location.pile.cards.skip(location.row + 1).forEach((card) {
              animatingCards.add(card);
            });
          });
        },
        onDragReturn: () {
          location.pile.cards.skip(location.row + 1).forEach((card) {
            animatingCards.remove(card);
          });
        },
        onDragAccept: (Offset releasedOffset) {
          draggedLocation = null;
          location.pile.cards.skip(location.row + 1).forEach((card) {
            animatingCards.remove(card);
          });
          final targetPile = hoveredPile!;
          final acceptedPile = releasedCardDestination[card.standardCard]!.pile;
          setState(() {
            releasedNotifier.value = HoverReleaseDetails(
              card: card.standardCard,
              acceptedPile: acceptedPile,
              offset: releasedOffset,
            );
            game.moveToPile(releasedCardOrigin[card.standardCard]!, targetPile);
          });
        },
        canHover: game.canDrag(location),
        canDrag: game.canDrag(location),
        releasedNotifier: releasedNotifier,
        shouldUpdateOnRelease: (HoverReleaseDetails? details) {
          if (details == null) return false;
          return details.card == card.standardCard;
          // if (releasedCardOrigin[card.standardCard] == location) {
          //   print('nice la cunt');
          //   print(releasedCardOrigin);
          // }
          // return releasedCardDestination[card.standardCard] == location;
        },
        builder: (context, child, elevation, isDragged, scale) {
          if (isDragged) {
            final SolitairePile cardsBelow =
                location.pile.peekPileFrom(location.row);
            return OverlapStack(childrenOffset: tableauCardOffset, children: [
              for (SolitaireCard card in cardsBelow.cards) ...{
                PokerCard(
                  card: card,
                  elevation: elevation,
                  width: cardWidth,
                ),
              }
            ]);
          } else {
            return Opacity(
              opacity: isRenderedByAnotherCard ? 0 : 1,
              child: PokerCard(
                card: card,
                elevation: elevation,
                width: cardWidth,
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildStockPile(SolitairePile pile) {
    final SolitaireCard card =
        SolitaireCard.fromStandardCard(ace.of(Suit.spades), isFaceDown: true);
    return Tooltip(
      key: pileKeys[pile],
      message: '翻开',
      waitDuration: const Duration(seconds: 1),
      child: Stack(
        alignment: Alignment.center,
        children: [
          DraggableCard<SolitaireCardLocation>(
            elevation: 10.0,
            hoverElevation: 10.0,
            canDrag: false,
            canHover: true,
            builder: (context, child, elevation, isDragged, scale) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  PokerCard(
                    card: card,
                    elevation: elevation,
                    width: cardWidth,
                    onTap: () {
                      if(pile.size>0){
                        drawFromStockPile();
                      }else{

                      }
                    },
                  ),
                  if(pile.size>0)
                  Center(
                    child: Icon(
                      Icons.pan_tool,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                  if(pile.size == 0)
                    Center(
                      child: IconButton(
                        icon:const Icon(Icons.refresh),
                        color: Theme.of(context).hintColor,
                        onPressed: (){
                          //TODO:重置
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPile(SolitairePile pile,
      {Offset? verticalCardOffset, bool halfGutters = false}) {
    verticalCardOffset ??= tableauCardOffset;
    return DragTarget<SolitaireCardLocation>(
      key: pileKeys[pile],
      onLeave: (details) {},
      onWillAccept: (SolitaireCardLocation? location) {
        if (location == null) {
          return false;
        } else {
          return game.canMoveToPile(location, pile);
        }
      },
      onMove: (DragTargetDetails<SolitaireCardLocation> details) {
        if (hoveredPile != pile) {
          setState(() {
            hoveredPile = pile;
          });
        }
      },
      onAccept: (SolitaireCardLocation originalLocation) {
        final movedCard = game.cardAt(originalLocation);
        releasedCardOrigin[movedCard.standardCard] = originalLocation;
        releasedCardDestination[movedCard.standardCard] =
            SolitaireCardLocation(row: pile.size, pile: pile);
      },
      builder: (context, List<SolitaireCardLocation?> locations,
              List<dynamic> rejectedData) =>
          Padding(
        padding: EdgeInsets.only(
          left: gutterWidth * (halfGutters ? 0.5 : 1),
          right: gutterWidth * (halfGutters ? 0.5 : 1),
          bottom: verticalCardOffset!.dy * 2.0,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _buildEmptyCard(),
            if (pile.isNotEmpty)
              OverlapStack.builder(
                itemBuilder: (context, row) {
                  return _buildCard(pile.cardAt(row),
                      SolitaireCardLocation(row: row, pile: pile));
                },
                itemCount: pile.size,
                childrenOffset: verticalCardOffset,
              ),
            if (locations.isNotEmpty)
              Transform.translate(
                offset: verticalCardOffset * pile.size.toDouble(),
                child: OverlapStack.builder(
                  itemBuilder: (context, row) {
                    return _buildCardOutline();
                  },
                  itemCount:
                      (locations.first!.pile.size) - (locations.first!.row),
                  childrenOffset: verticalCardOffset,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard() {
    return PokerCard(width: cardWidth);
  }

  Widget _buildCardOutline() {
    return PokerCard.transparent(width: cardWidth);
  }

  void drawFromStockPile() {
    setState(() {
      StockPileMove move = game.drawFromStock();
      releasedNotifier.value = null;
      final Offset initialOffset = _getOffset(move.origin);
      releasedCardOrigin[move.card.standardCard] = move.origin;
      releasedCardDestination[move.card.standardCard] = move.destination;
      final acceptedPile = move.destination.pile;
      releasedNotifier.value = HoverReleaseDetails(
          card: move.card.standardCard,
          acceptedPile: acceptedPile,
          offset: initialOffset);
    });
  }

  void startNewGame(BuildContext context) {
    final SolitaireGame thisGame = game;
    hoveredLocation = null;
    draggedLocation = null;
    releasedCardOrigin = {};
    releasedCardDestination = {};
    releasedNotifier = ValueNotifier(null);
    hoveredPile = null;
    animatingCards = HashSet();
    Map<Pile,GlobalKey> key = pileKeys;

    ScaffoldMessenger.of(context).showSnackBar( SnackBar(
      behavior: SnackBarBehavior.floating,
      width: 300,
      content: const Text('已开始新游戏'),
      action: SnackBarAction(
        label: '撤销',
        onPressed: () {
          setState(() {
            game = thisGame;
            pileKeys = key;
          });
        },
      ),
    ));

    game = SolitaireGame();
    game.won.addListener(onGameWinUpdate);
    pileKeys = {
      for (Pile pile in game.allPiles) pile: GlobalKey()
    };
    winAnimationController.reverse();
  }

  void undoPreviousMove() {
    setState(() {
      Move move = game.previousMove!;
      if (move is PileMove) {
        animatePileMove(move.card, move.destination, move.origin);
      }
      game.undo();
    });
  }

  void redoPreviousMove() {
    setState(() {
      Move move = game.previousUndoneMove!;
      if (move is PileMove) {
        animatePileMove(move.card, move.origin, move.destination);
      }
      game.redo();
    });
  }

  void animatePileMove(SolitaireCard card, SolitaireCardLocation origin,
      SolitaireCardLocation destination) {
    final Offset initialOffset = _getOffset(origin);
    releasedCardOrigin[card.standardCard] = destination;
    releasedCardDestination[card.standardCard] = origin;
    final acceptedPile = origin.pile;
    releasedNotifier.value = HoverReleaseDetails(
      card: card.standardCard,
      acceptedPile: acceptedPile,
      offset: initialOffset,
    );
  }

  Offset _getOffset(SolitaireCardLocation location) {
    final GlobalKey pileKey = pileKeys[location.pile]!;
    final Offset offset =
        (pileKey.currentContext!.findRenderObject() as RenderBox)
            .localToGlobal(Offset.zero);
    SolitairePile pile = location.pile;
    if (game.isFoundationPile(pile) || game.isStockPile(pile)) {
      return offset;
    } else if (game.isWastePile(pile)) {
      return offset + wasteCardOffset * location.row.toDouble();
    } else {
      return offset + tableauCardOffset * location.row.toDouble();
    }
  }

  void tryMoveToFoundation(SolitaireCard card, SolitaireCardLocation location) {
    setState(() {
      PileMove? move = game.tryMoveToFoundation(card);
      if (move != null) {
        animatePileMove(move.card, move.origin, move.destination);
      }
    });
  }
}
