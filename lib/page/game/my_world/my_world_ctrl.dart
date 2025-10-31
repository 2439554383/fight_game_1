import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../player/player_ctrl.dart';

class MyWorld extends World with TapCallbacks {
  late Player player;

  @override
  Future<void> onLoad() async {
    player = Player(position: Vector2(-400, 0));
    add(player);
  }

  @override
  void onTapUp(TapUpEvent event) {
    // 获取点击的世界坐标
    // event.localPosition是相对于World的坐标，已经是世界坐标
    final targetPosition = event.localPosition;
    
    // 让player移动到目标位置
    player.moveToPosition(targetPosition);
  }
}