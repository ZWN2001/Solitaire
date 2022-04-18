import 'package:flutter/material.dart';

//快捷键Intent
class UndoIntent extends Intent {
  const UndoIntent();
}

class RedoIntent extends Intent {
  const RedoIntent();
}

class NewGameIntent extends Intent {
  const NewGameIntent();
}

class MoveCardsToFoundationIntent extends Intent {
  const MoveCardsToFoundationIntent();
}

class DrawFromStockIntent extends Intent {
  const DrawFromStockIntent();
}
