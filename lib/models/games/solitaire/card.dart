import 'package:quards/models/deck.dart';

/*
 * @Date  3.29
 * @Description 纸牌实体类
 * @Since version-1.0
 */

class SolitaireCard {
  /*
   * @Param
   * suit:花色，value：值，isfacedown：是否翻面
   * @Since version-1.0
   */
  SolitaireCard(Suit suit, int value) : _card = StandardCard(suit, value);
  SolitaireCard.fromStandardCard(this._card, {required bool isFaceDown}) {
    _faceDown = isFaceDown;
  }

  final StandardCard _card;

  StandardCard get standardCard => _card;

  Suit get suit => _card.suit;
  int get value => _card.value;
  bool get isRed => _card.isRed;

  bool _faceDown = false;

  bool get isFaceDown => _faceDown;

  String get valueString => _card.valueString;

  ///翻面方法
  void flip() {
    _faceDown = !_faceDown;
  }

  //最基本的条件：红黑牌相间
  bool canBePlacedBelow(SolitaireCard card) {
    return card._card.isRed != _card.isRed;
  }

  @override
  String toString() {
    return _card.toString();
  }
}
