import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class Player extends SpriteAnimationComponent with KeyboardHandler{
  Player({super.position})
      : super(size: Vector2.all(200), anchor: Anchor.center);

  late SpriteAnimation runAnimation;
  late SpriteAnimation idleAnimation;

  @override
  Future<void> onLoad() async {
    // 加载所有图片并创建动画
    final sprites = <Sprite>[];
    for(int i = 0; i < 8; i++){
      sprites.add(await Sprite.load('run$i.png'));
    }
    final idle = await Sprite.load('idle.png');
    runAnimation = SpriteAnimation.spriteList(
      sprites,
      stepTime: 0.1, // 每帧时间
      loop: true,    // 循环播放
    );
    
    // 创建待机动画（使用第一帧）
    idleAnimation = SpriteAnimation.spriteList(
      [idle],
      stepTime: 0.15,
      loop: true,
    );
    
    // 设置初始动画为待机
    animation = idleAnimation;
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed){
    // 检查是否有移动按键按下
    bool isMoving = keysPressed.contains(LogicalKeyboardKey.keyW) ||
                    keysPressed.contains(LogicalKeyboardKey.keyS) ||
                    keysPressed.contains(LogicalKeyboardKey.keyA) ||
                    keysPressed.contains(LogicalKeyboardKey.keyD);
    
    // 如果没有移动键按下，立即停止移动
    if (!isMoving) {
      removeWhere((component) => component is MoveAlongPathEffect);
      animation = idleAnimation;
      return true;
    } else {
      // 有按键按下，播放跑步动画
      animation = runAnimation;
    }
    // 处理按键逻辑
    if(keysPressed.contains(LogicalKeyboardKey.keyW)){
      final targetPosition = Vector2(position.x , position.y -50);
      moveToPosition(targetPosition);
    }
    if(keysPressed.contains(LogicalKeyboardKey.keyS)){
      final targetPosition = Vector2(position.x , position.y +50);
      moveToPosition(targetPosition);
    }
    if(keysPressed.contains(LogicalKeyboardKey.keyA)){
      final targetPosition = Vector2(position.x - 50, position.y);
      moveToPosition(targetPosition);
    }
    if(keysPressed.contains(LogicalKeyboardKey.keyD)){
      final targetPosition = Vector2(position.x + 50, position.y);
      moveToPosition(targetPosition);
    }
    
    return true; // 允许传播，或 false 阻止传播
  }

  void moveToPosition(Vector2 targetPosition) {
    // 移除现有的移动效果（如果存在）
    removeWhere((component) => component is MoveAlongPathEffect);

    // 切换到跑步动画
    animation = runAnimation;

    // 计算当前位置到目标位置的路径
    final currentPos = position;
    final distance = (targetPosition - currentPos).length;
    
    // 创建曲线路径：使用二次贝塞尔曲线
    // 控制点设置在路径中间的上方，形成弧形
    final controlPoint = Vector2(
      (currentPos.x + targetPosition.x) / 2,
      (currentPos.y + targetPosition.y) / 2,
      // (currentPos.y + targetPosition.y) / 2 - distance * 0.3, // 向上偏移形成弧形
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