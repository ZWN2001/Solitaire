///纸牌堆类
/// Represents a solitaire pile
/// 最小的索引表示牌堆底部的牌
/// 索引（下标）值越大，牌在牌堆中越靠上
/// The lowest index represents the bottom of the pile
/// (也就是被好多牌压在底下的牌）
/// (the card which has the all the other cards lying on top of it)
/*
 * @Date  3.29
 * @Description 纸牌堆类
 * 维护一个盛放Card的列表
 * @Since version-1.0
 */

class Pile<Card> {
  const Pile(List<Card> cards) : _cards = cards;
  final List<Card> _cards;

  Iterable<Card> get cards => _cards;

  int get size => _cards.length;

  /// 牌堆最顶部的牌
  Card? get topCard => size > 0 ? _cards.last : null;

  /// 牌堆最底部的牌（在List的最开头）
  Card? get bottomCard => size > 0 ? _cards.first : null;

  Card cardAt(int n) {
    return _cards.elementAt(n);
  }

  //找这张牌在牌堆中的位置（下标）
  int rowOf(Card card) {
    return _cards.indexOf(card);
  }

  bool get isEmpty => _cards.isEmpty;
  bool get isNotEmpty => _cards.isNotEmpty;

  Pile<Card> removePileFrom(int index) {
    //返回从index到最后的 List 的数据，包括 index。也就是排队顶部被移走的牌
    List<Card> removedCards = _cards.skip(index).toList();
    //删除从index到最后的数据，前闭后开。
    _cards.removeRange(index, _cards.length);
    return Pile<Card>(removedCards);
  }

  //移走第一张牌
  Pile<Card> removeTopCard() {
    return removePileFrom(size - 1);
  }

  //取牌堆的第一张牌，返回
  Pile<Card> peekTopCard() {
    return peekPileFrom(size - 1);
  }

  //只取牌，但不改变牌堆List数据，返回取到的牌（堆）
  Pile<Card> peekPileFrom(int index) {
    List<Card> cards = _cards.skip(index).toList();
    return Pile<Card>(cards);
  }

  //向牌堆加牌（尾部追加）
  void appendPile(Pile<Card> pile) {
    _cards.addAll(pile._cards);
  }

  @override
  String toString() {
    return cards.toString();
  }
}
