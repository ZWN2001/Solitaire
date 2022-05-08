import 'card.dart';
import 'solitaire.dart';

abstract class Move {
  void execute();

  void undo();
}

abstract class PileMove extends Move {
  PileMove(this.origin, this.targetPile)
      : oldTargetPileSize = targetPile.size,
        destination =
            SolitaireCardLocation(row: targetPile.size, pile: targetPile),
        card = origin.pile.cardAt(origin.row);
  final SolitaireCardLocation origin;
  final SolitaireCardLocation destination;
  final SolitairePile targetPile;
  final int oldTargetPileSize;
  final SolitaireCard card;

  @override
  void execute() {
    SolitairePile originPile = origin.pile;
    SolitairePile movedPile = originPile.removePileFrom(origin.row);
    targetPile.appendPile(movedPile);
  }

  @override
  void undo() {
    SolitairePile movedPile = targetPile.removePileFrom(oldTargetPileSize);
    SolitairePile originPile = origin.pile;
    originPile.appendPile(movedPile);
  }
}

/// Like a pile move, 维护中间七个牌堆间的移动
class TableauPileMove extends PileMove {
  SolitaireCard? flippedCard;

  TableauPileMove(SolitaireCardLocation origin, SolitairePile targetPile)
      : super(origin, targetPile);

  @override
  void execute() {
    super.execute();
    SolitairePile originPile = origin.pile;
    if (originPile.topCard != null) {
      if (originPile.topCard!.isFaceDown) {
        originPile.topCard!.flip();
        flippedCard = originPile.topCard;
      }
    }
  }

  @override
  void undo() {
    super.undo();
    flippedCard?.flip();
  }
}

///主要维护左侧预备牌堆的移动
class StockPileMove extends PileMove {
  StockPileMove(this.stock)
      : super(
            SolitaireCardLocation(
                row: stock.stockPile.size - 1, pile: stock.stockPile),
            stock.wastePile);
  SolitaireStock stock;

  @override
  void execute() {
    move(stock.stockPile, stock.wastePile);
  }

  @override
  void undo() {
    move(stock.wastePile, stock.stockPile);
  }

  void move(SolitairePile fromPile, SolitairePile toPile) {
    if (fromPile.isNotEmpty) {
      final SolitairePile topCardPile = fromPile.peekTopCard();
      topCardPile.topCard!.flip();
      if (fromPile == stock.stockPile) {
        super.execute();
      } else {
        super.undo();
      }
    } else {
      // // Stock pile is empty, return all from waste pile to stock pile
      // while (fromPile.isNotEmpty) {
      //   final SolitairePile topCardPile = fromPile.removeTopCard();
      //   topCardPile.topCard!.flip();
      //   toPile.appendPile(topCardPile);
      // }
    }
  }

  @override
  String toString() {
    return 'StockPileMove{stock: $stock}';
  }
}

///stock中没有牌了，将waste移回
class StockPileMoveBack extends PileMove {
  StockPileMoveBack(this.stock)
      : super(
            SolitaireCardLocation(
                row: stock.wastePile.size - 1, pile: stock.wastePile),
            stock.stockPile);
  SolitaireStock stock;

  @override
  void execute() {}

  @override
  void undo() {}

  void move(SolitairePile fromPile, SolitairePile toPile) {
    // Stock pile is empty, return all from waste pile to stock pile
    while (fromPile.isNotEmpty) {
      final SolitairePile topCardPile = fromPile.removeTopCard();
      topCardPile.topCard!.flip();
      toPile.appendPile(topCardPile);
    }
  }

  void moveBack() {
    move(stock.wastePile, stock.stockPile);
  }

  @override
  String toString() {
    return 'StockPileMoveBack{stock: $stock}';
  }
}
