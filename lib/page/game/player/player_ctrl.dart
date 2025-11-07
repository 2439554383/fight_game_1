import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';
import 'package:flame/sprite.dart';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:untitled1/page/game/start_game_ctrl.dart';

import '../enemy/enemy_ctrl.dart';

/// 玩家角色组件
/// 负责处理角色的移动、攻击、防御、跳跃等所有行为
class Player extends SpriteAnimationComponent
    with KeyboardHandler, HasGameRef, CollisionCallbacks {
  Player({super.position})
    : super(size: Vector2(128, 128), anchor: Anchor.center);

  // ============ 常量定义 ============

  /// 精灵图帧大小
  static final frameSize = Vector2(128, 128);

  /// 正常移动速度（像素/秒）
  static const double moveSpeed = 200.0;

  /// 攻击时的移动速度（跑步时攻击，移动速度降低）
  static const double attackMoveSpeed = 40.0;

  /// 动画每帧的播放时间（秒）
  static const double animationStepTime = 0.05;

  /// 攻击连击窗口时间（毫秒）
  static const int attackComboWindowMs = 700;

  /// 动画名称列表（按索引顺序）
  static const List<String> actionNames = [
    "Idle",
    "Walk",
    "Run",
    "Jump",
    "Protect",
    "Attack_1",
    "Attack_2",
    "Attack_3",
    "Hurt",
    "Dead",
  ];

  /// 动画循环列表（对应 actionNames）
  static const List<bool> animationLoops = [
    true, // Idle: 循环
    true, // Walk: 循环
    true, // Run: 循环
    false, // Jump: 不循环
    false, // Protect: 不循环
    false, // Attack_1: 不循环
    false, // Attack_2: 不循环
    false, // Attack_3: 不循环
    false, // Hurt: 不循环
    false, // Dead: 不循环
  ];

  /// 移动键集合（用于判断是否为移动键）
  static final Set<LogicalKeyboardKey> movementKeys = {
    LogicalKeyboardKey.keyW,
    LogicalKeyboardKey.keyS,
    LogicalKeyboardKey.keyA,
    LogicalKeyboardKey.keyD,
  };

  /// 动作动画索引范围（攻击、防御、跳跃、受伤、死亡）
  static const int actionAnimationStartIndex = 4;
  static const int actionAnimationEndIndex = 9;

  /// 动画索引常量
  static const int animationIndexIdle = 0;
  static const int animationIndexWalk = 1;
  static const int animationIndexRun = 2;
  static const int animationIndexJump = 3;
  static const int animationIndexProtect = 4;
  static const int animationIndexAttackStart = 5;
  static const int animationIndexAttackEnd = 7;

  // ============ 实例变量 ============

  /// 所有动画列表
  late List<SpriteAnimation> animationList;

  /// 每个动画的帧数列表（用于计算动画时长）
  late List<int> frameList;

  /// 当前按下的移动键集合
  final Set<LogicalKeyboardKey> pressedMovementKeys = {};

  /// 当前移动方向向量（归一化）
  Vector2 currentMoveDirection = Vector2.zero();

  /// 攻击连击计数（1-3）
  int attackCount = 0;

  /// 上次攻击的时间
  DateTime? lastAttackTime;

  /// 当前攻击动画开始时间
  DateTime? attackStartTime;

  /// 动作是否完成（用于判断是否可以执行新动作）
  bool actionComplete = true;

  // ============ 生命周期方法 ============

  /// 初始化：加载所有动画资源
  @override
  Future<void> onLoad() async {
    await loadAnimations();
    initializePlayer();
    add(RectangleHitbox(collisionType: CollisionType.active));
  }

  /// 每帧更新：处理移动、攻击动画完成检测等
  @override
  void update(double dt) {
    super.update(dt);

    final currentAnimationIndex = getCurrentAnimationIndex();
    final isProtecting = currentAnimationIndex == animationIndexProtect;
    final isAttacking = isAttackingAnimation(currentAnimationIndex);

    // 防御时完全禁止移动
    if (isProtecting) {
      clearMoveEffects();
      return;
    }

    // 处理持续移动
    handleContinuousMovement(dt, isAttacking);

    // 检查攻击动画是否完成
    checkAttackAnimationCompletion();
  }

  // ============ 键盘事件处理 ============

  /// 处理键盘事件：更新按键状态并触发相应动作
  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyDownEvent) {
      handleKeyDown(event);
    } else if (event is KeyUpEvent) {
      handleKeyUp(event);
    }

    return true;
  }

  /// 处理按键按下事件
  void handleKeyDown(KeyDownEvent event) {
    handleVirtualKeyDown(event.logicalKey);
  }

  /// 处理按键松开事件
  void handleKeyUp(KeyUpEvent event) {
    handleVirtualKeyUp(event.logicalKey);
  }

  /// 虚拟按键按下（用于移动端或手柄）
  void handleVirtualKeyDown(LogicalKeyboardKey key) {
    if (movementKeys.contains(key)) {
      pressedMovementKeys.add(key);
      updateMoveDirection();
    }

    switch (key) {
      case LogicalKeyboardKey.keyJ:
        playAttack();
        break;
      case LogicalKeyboardKey.keyK:
        playProtect();
        break;
      case LogicalKeyboardKey.space:
        playJump();
        break;
      default:
        break;
    }
  }

  /// 虚拟按键松开（用于移动端或手柄）
  void handleVirtualKeyUp(LogicalKeyboardKey key) {
    if (movementKeys.contains(key)) {
      pressedMovementKeys.remove(key);
      updateMoveDirection();
    }
  }

  // ============ 移动相关方法 ============

  /// 更新移动方向：根据当前按下的按键计算移动向量和朝向
  void updateMoveDirection() {
    // 重置移动方向
    currentMoveDirection = Vector2.zero();

    // 根据按下的键计算移动向量
    if (pressedMovementKeys.contains(LogicalKeyboardKey.keyW)) {
      currentMoveDirection.y -= 1; // 向上
    }
    if (pressedMovementKeys.contains(LogicalKeyboardKey.keyS)) {
      currentMoveDirection.y += 1; // 向下
    }
    if (pressedMovementKeys.contains(LogicalKeyboardKey.keyA)) {
      currentMoveDirection.x -= 1; // 向左
    }
    if (pressedMovementKeys.contains(LogicalKeyboardKey.keyD)) {
      currentMoveDirection.x += 1; // 向右
    }

    // 归一化方向向量（使对角线移动速度与垂直/水平移动速度一致）
    if (currentMoveDirection.length > 0) {
      currentMoveDirection.normalize();
    }

    // 更新角色朝向和动画
    updateFacingDirection();
    updateMovementAnimation();
  }

  /// 更新角色朝向：根据水平移动方向翻转角色
  void updateFacingDirection() {
    final hasA = pressedMovementKeys.contains(LogicalKeyboardKey.keyA);
    final hasD = pressedMovementKeys.contains(LogicalKeyboardKey.keyD);

    // 如果同时按了A和D，或者都没按，保持当前朝向
    if ((hasA && hasD) || (!hasA && !hasD)) {
      return;
    }

    // 按A键：面向左（向后），使用 scale.x = -1 进行水平翻转
    if (hasA) {
      scale.x = -1;
    }
    // 按D键：面向右（向前），恢复正常方向
    else if (hasD) {
      scale.x = 1;
    }
  }

  /// 更新移动相关的动画：根据移动状态切换跑步或待机动画
  void updateMovementAnimation() {
    final currentIndex = getCurrentAnimationIndex();
    final isActionAnim = isActionAnimation(currentIndex);

    // 有移动方向且不在动作动画中，切换到跑步动画
    if (currentMoveDirection.length > 0) {
      clearMoveEffects();
      if (!isActionAnim) {
        animation = animationList[animationIndexRun];
      }
    }
    // 没有移动，且不在动作动画中，切回待机动画
    else {
      clearMoveEffects();
      if (!isActionAnim) {
        animation = animationList[animationIndexIdle];
      }
    }
  }

  /// 处理持续移动：每帧根据移动方向更新位置
  void handleContinuousMovement(double dt, bool isAttacking) {
    if (currentMoveDirection.length > 0) {
      // 计算移动速度（攻击时降低速度）
      final moveSpeed = isAttacking ? attackMoveSpeed : Player.moveSpeed;

      // 计算这一帧的移动距离并更新位置
      final moveDistance = moveSpeed * dt;
      final moveDelta = currentMoveDirection * moveDistance;
      position += moveDelta;
    } else {
      // 没有按方向键时，如果正在攻击，清除移动效果（防止惯性移动）
      if (isAttacking) {
        clearMoveEffects();
      }
    }
  }

  @override
  void onCollision(Set<Vector2> points, PositionComponent other) {
    super.onCollision(points, other);
    if (other is ScreenHitbox) {
      print("检测到屏幕边缘碰撞");
      //...
    } else if (other is Enemy) {
      StartGameCtrl ctrl = Get.find<StartGameCtrl>();
      if (ctrl.bloodVolume > 0.1) {
        ctrl.changeBlood();
      } else {
        print("玩家死亡");
      }
      print("以碰撞到敌人");
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);
    if (other is ScreenHitbox) {
      //...
    }
    // else if (other is YourOtherComponent) {
    //   //...
    // }
  }

  // ============ 动画控制方法 ============

  /// 播放待机动画
  void playIdle() {
    animation = animationList[animationIndexIdle];
  }

  /// 播放行走动画
  void playWalk() {
    animation = animationList[animationIndexWalk];
  }

  /// 播放跑步动画
  void playRun() {
    animation = animationList[animationIndexRun];
  }

  /// 播放跳跃动画
  void playJump() {
    animation = animationList[animationIndexJump];
  }

  /// 播放防御动画
  void playProtect() {
    animation = animationList[animationIndexProtect];
  }

  void playHurt() {
    animation = animationList[animationIndexProtect];
  }

  void playDead() {
    animation = animationList[animationIndexProtect];
  }

  /// 播放攻击动画：支持连击（最多3次）
  void playAttack() {
    // 如果动作未完成，不允许新的攻击
    if (!actionComplete) {
      return;
    }

    final now = DateTime.now();

    // 判断是否在连击窗口内（1000ms内）
    final inComboWindow =
        lastAttackTime != null &&
        now.difference(lastAttackTime!).inMilliseconds < attackComboWindowMs;

    // 在连击窗口内且未达到最大连击数，连击数+1；否则重置为1
    if (inComboWindow && attackCount < 3) {
      attackCount++;
    } else {
      attackCount = 1;
    }

    // 设置对应的攻击动画（Attack_1是索引5，Attack_2是6，Attack_3是7）
    animation = animationList[animationIndexProtect + attackCount];
    lastAttackTime = now;
    attackStartTime = now;
  }

  // ============ 攻击动画完成检测 ============

  /// 检查攻击动画是否完成，并自动切换到合适的动画
  void checkAttackAnimationCompletion() {
    if (attackStartTime == null || lastAttackTime == null) {
      actionComplete = true;
      return;
    }

    final currentIndex = getCurrentAnimationIndex();

    // 如果当前不是攻击动画，标记为完成
    if (!isAttackingAnimation(currentIndex)) {
      actionComplete = true;
      return;
    }

    // 计算攻击动画的时长
    final attackDuration = calculateAttackDuration();

    // 检查攻击动画是否已经完成
    final timeSinceAttackStart = DateTime.now()
        .difference(attackStartTime!)
        .inMilliseconds;
    final attackDurationMs = (attackDuration * 1000).round();

    if (timeSinceAttackStart >= attackDurationMs) {
      actionComplete = true;

      // 检查距离上次攻击的时间
      final timeSinceLastAttack = DateTime.now()
          .difference(lastAttackTime!)
          .inMilliseconds;

      // 如果超过连击窗口时间，说明没有新攻击，切换到合适动画
      if (timeSinceLastAttack >= attackComboWindowMs) {
        final checkIndex = getCurrentAnimationIndex();

        // 确保当前仍然是攻击动画（避免被其他逻辑改变）
        if (isAttackingAnimation(checkIndex)) {
          // 根据是否还在移动来决定动画
          if (currentMoveDirection.length > 0) {
            animation = animationList[animationIndexRun]; // 切换到跑步动画
          } else {
            animation = animationList[animationIndexIdle]; // 切换到待机动画
          }
          attackStartTime = null;
        }
      }
    } else {
      actionComplete = false;
    }
  }

  /// 计算当前攻击动画的时长（秒）
  double calculateAttackDuration() {
    final attackIndex = animationIndexProtect + attackCount;
    final frameCount = frameList[attackIndex];
    return frameCount * animationStepTime;
  }

  // ============ 动画加载方法 ============

  /// 加载所有动画资源
  Future<void> loadAnimations() async {
    // 加载所有精灵图
    final imageFutures = actionNames
        .map((action) => gameRef.images.load('Samurai_Commander/$action.png'))
        .toList();

    final imageList = await Future.wait(imageFutures);

    // 计算每个动画的帧数
    frameList = imageList
        .map((image) => (image.width / frameSize.x).floor())
        .toList();

    // 创建精灵表单列表
    final sheetList = imageList
        .map((image) => SpriteSheet(image: image, srcSize: frameSize))
        .toList();

    // 创建动画列表
    animationList = List.generate(
      sheetList.length,
      (index) => sheetList[index].createAnimation(
        row: 0,
        from: 0,
        to: frameList[index],
        stepTime: animationStepTime,
        loop: animationLoops[index],
      ),
    );
  }

  /// 初始化玩家：设置初始动画和朝向
  void initializePlayer() {
    animation = animationList[animationIndexIdle];
    scale.x = 1; // 初始朝向为向右（向前）
  }

  // ============ 工具方法 ============

  /// 判断指定动画索引是否为动作动画（不可中断）
  bool isActionAnimation(int animationIndex) {
    return animationIndex >= actionAnimationStartIndex &&
        animationIndex <= actionAnimationEndIndex;
  }

  /// 判断指定动画索引是否为攻击动画
  bool isAttackingAnimation(int animationIndex) {
    return animationIndex >= animationIndexAttackStart &&
        animationIndex <= animationIndexAttackEnd;
  }

  /// 获取当前动画的索引
  int getCurrentAnimationIndex() {
    return animationList.indexOf(animation!);
  }

  /// 清除所有移动效果
  void clearMoveEffects() {
    removeWhere((component) => component is MoveAlongPathEffect);
  }

  /// 移动到目标位置（使用路径效果，保留用于可能的点击移动功能）
  void moveToPosition(Vector2 targetPosition) {
    final currentIndex = getCurrentAnimationIndex();
    final isActionAnim = isActionAnimation(currentIndex);

    clearMoveEffects();

    if (!isActionAnim) {
      animation = animationList[animationIndexRun];
    }

    moveToPositionDirect(targetPosition);
  }

  /// 直接移动到目标位置（使用贝塞尔曲线路径）
  void moveToPositionDirect(Vector2 targetPosition) {
    final currentPos = position;
    final distance = (targetPosition - currentPos).length;

    // 距离太短，不需要移动
    if (distance < 1.0) {
      return;
    }

    // 创建二次贝塞尔曲线路径
    final controlPoint = Vector2(
      (currentPos.x + targetPosition.x) / 2,
      (currentPos.y + targetPosition.y) / 2,
    );

    final path = ui.Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(
        controlPoint.x - currentPos.x,
        controlPoint.y - currentPos.y,
        targetPosition.x - currentPos.x,
        targetPosition.y - currentPos.y,
      );

    // 根据距离计算移动时间
    final duration = (distance / 200).clamp(0.5, 3.0);

    // 添加移动效果
    add(MoveAlongPathEffect(path, EffectController(duration: duration)));
  }
}
