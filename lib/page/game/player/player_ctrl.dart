import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';
import 'dart:ui' as ui;

class Player extends SpriteComponent {
  Player({super.position})
      : super(size: Vector2.all(200), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('player.png');
  }

  void moveToPosition(Vector2 targetPosition) {
    // 移除现有的移动效果（如果存在）
    removeWhere((component) => component is MoveAlongPathEffect);

    // 计算当前位置到目标位置的路径
    final currentPos = position;
    final distance = (targetPosition - currentPos).length;
    
    // 创建曲线路径：使用二次贝塞尔曲线
    // 控制点设置在路径中间的上方，形成弧形
    final controlPoint = Vector2(
      (currentPos.x + targetPosition.x) / 2,
      (currentPos.y + targetPosition.y) / 2 - distance * 0.3, // 向上偏移形成弧形
    );

    // 创建Path，相对于当前位置
    final path = ui.Path()
      ..moveTo(0, 0) // 从当前位置开始
      ..quadraticBezierTo(
        controlPoint.x - currentPos.x, // 相对坐标
        controlPoint.y - currentPos.y, // 相对坐标
        targetPosition.x - currentPos.x, // 相对坐标
        targetPosition.y - currentPos.y, // 相对坐标
      );

    // 根据距离计算移动时间（距离越远，时间越长）
    final duration = (distance / 200).clamp(0.5, 3.0);

    // 创建移动效果
    final moveEffect = MoveAlongPathEffect(
      path,
      EffectController(duration: duration),
    );

    // 添加效果到player
    add(moveEffect);
  }
}