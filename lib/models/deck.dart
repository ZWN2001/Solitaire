library cards;

import 'package:equatable/equatable.dart';

//牌组抽象类（52张牌）
abstract class Deck<Card> {
  Deck(this.cards) : _size = cards.length;

  List<Card> cards;
  int get size => _size;
  set size(int value) {
    //返回指定范围内离当前数值最近的数，如果num在返回内返回num
    _size = value.clamp(0, double.infinity).toInt();
  }

  int _size;
  bool get isEmpty => cards.isEmpty;
  bool get isNotEmpty => cards.isNotEmpty;

  Card peek() {
    return cards.first;
  }

  Iterable<Card> peekN(int n) {
    return cards.take(n);
  }

  Card cardAt(int n) {
    return cards.elementAt(n);
  }

  //取一张牌
  Card take() {
    assert(cards.isNotEmpty, '牌堆为空');
    cards = cards.skip(1).toList();
    size -= 1;
    return cards.first;
  }

  //取 n 张牌
  Iterable<Card> takeN(int n) {
    assert(size >= n, '只有${cards.length}张牌，不足$n张');
    //依次取List的前n个元素
    final Iterable<Card> nCards = cards.take(n);
    //修改牌堆数据
    cards = cards.skip(n).toList();
    return nCards;
  }

  //打乱牌堆
  void shuffle() {
    cards.shuffle();
  }
}

class StandardDeck extends Deck<StandardCard> {
  StandardDeck.shuffled()
      : super(Suit.values
                //对于四种花色
            .expand((suit) =>
                //随机生成 1~13（A~K）
                List.generate(13, (index) => StandardCard(suit, index + 1)))
            .toList()
              ..shuffle());
}

enum Suit {
  ///梅花
  clubs,
  ///方块
  diamonds,
  ///红桃
  hearts,
  ///黑桃
  spades,
}

///A
const ace = 1;
///J
const jack = 11;
///Q
const queen = 12;
///K
const king = 13;

//Equatable可以自动覆写 ==和 hashCode
/*
 * @Description 纸牌基类，用于规定纸牌的花色与值
 */
class StandardCard extends Equatable {
  const StandardCard(this.suit, this.value)
      : assert(value >= ace),
        assert(value <= king);

  final Suit suit;
  final int value;

  //红黑牌：方块与红桃都是红牌
  bool get isRed => suit == Suit.diamonds || suit == Suit.hearts;

  String get valueString {
    if (value == ace) {
      return 'A';
    } else if (value == jack) {
      return 'J';
    } else if (value == queen) {
      return 'Q';
    } else if (value == king) {
      return 'K';
    } else {
      return value.toString();
    }
  }

  @override
  String toString() {
    return '$value${suit.toDisplayString()}';
  }

  @override
  List<Object?> get props => [suit, value];
}

extension SuitString on Suit {
  String toDisplayString() {
    if (this == Suit.clubs) {
      return '♣';
    } else if (this == Suit.diamonds) {
      return '♦';
    } else if (this == Suit.hearts) {
      return '♥';
    } else {
      return '♠';
    }
  }
}

extension CardHelper on int {
  StandardCard of(Suit suit) {
    return StandardCard(suit, this);
  }
}
