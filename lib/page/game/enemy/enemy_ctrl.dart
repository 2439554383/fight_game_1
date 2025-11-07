import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/sprite.dart';

import '../player/player_ctrl.dart';
import 'enemy_type.dart';

/// 敌人角色组件
/// 负责处理敌人的移动、攻击等AI行为
class Enemy extends SpriteAnimationComponent with HasGameRef,CollisionCallbacks {
  Enemy({
    required this.enemyType,
    required this.playerRef,
    super.position,
  }) : super(
          size: Vector2(128,128),
          anchor: Anchor.center,
        );

  /// 敌人类型
  final EnemyType enemyType;

  /// 敌人配置
  late final EnemyTypeConfig config;

  /// 玩家引用
  final Player playerRef;

  /// 所有动画列表
  late List<SpriteAnimation> animationList;

  /// 每个动画的帧数列表
  late List<int> frameList;

  /// 当前生命值
  int currentHealth = 0;

  /// 是否已死亡
  bool isDead = false;

  /// 是否正在攻击
  bool isAttacking = false;

  /// 上次攻击时间
  DateTime? lastAttackTime;

  /// 攻击动画开始时间
  DateTime? attackStartTime;

  /// 动画索引（动态获取，因为不同敌人类型的动画顺序可能不同）
  int get animationIndexIdle => 0;
  int get animationIndexWalk => 
      config.actionNames.contains('Walk') 
          ? config.actionNames.indexOf('Walk')
          : config.actionNames.contains('Flight')
              ? config.actionNames.indexOf('Flight')
              : 1;
  int get animationIndexAttack => 
      config.actionNames.indexOf('Attack');
  int get animationIndexHurt => 
      config.actionNames.indexOf('Hurt');
  int get animationIndexDeath => 
      config.actionNames.indexOf('Death');

  /// 动画每帧的播放时间（秒）
  static const double animationStepTime = 0.1;

  /// 精灵图帧大小（根据敌人类型动态调整）
  Vector2 get frameSize {
    // demon 和 lizard 的图片可能尺寸不同，使用实际图片尺寸
    switch (enemyType) {
      case EnemyType.demon:
      case EnemyType.lizard:
        return Vector2(64,64); // 较小的敌人使用64x64
      default:
        return Vector2(128,128); // 其他敌人使用128x128
    }
  }

  // ============ 生命周期方法 ============

  @override
  Future<void> onLoad() async {
    config = EnemyTypeConfig.getConfig(enemyType);
    currentHealth = config.health;
    await loadAnimations();
    initializeEnemy();
    add(
        RectangleHitbox(
            collisionType: CollisionType.passive
        )
    );
  }

  @override
  void onCollision(Set<Vector2> points, PositionComponent other) {
    super.onCollision(points, other);
    if (other is ScreenHitbox) {
      print("检测到屏幕边缘碰撞");
      //...
    }
    else if (other is Player) {
      print("检测到被人物碰撞");
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

  @override
  void update(double dt) {
    if (isDead) {
      return;
    }

    super.update(dt);

    final currentIndex = getCurrentAnimationIndex();

    // 如果正在播放死亡动画，不再执行其他逻辑
    if (currentIndex == animationIndexDeath) {
      return;
    }

    // 如果正在攻击，检查攻击动画是否完成
    if (isAttacking) {
      checkAttackAnimationCompletion();
      return;
    }

    // 计算到玩家的距离
    final distanceToPlayer = (position - playerRef.position).length;

    // 如果在攻击范围内，执行攻击
    if (distanceToPlayer <= config.attackRange) {
      playAttack();
    }
    // 否则向玩家移动
    else {
      moveTowardsPlayer(dt);
    }

    // 更新朝向
    updateFacingDirection();
  }

  // ============ 移动相关方法 ============

  /// 向玩家移动
  void moveTowardsPlayer(double dt) {
    final direction = (playerRef.position - position);

    if (direction.length > 0) {
      direction.normalize();

      // 更新位置
      final moveDistance = config.moveSpeed * dt;
      final moveDelta = direction * moveDistance;
      position += moveDelta;

      // 更新动画（移动时播放Walk或Flight动画）
      final currentIndex = getCurrentAnimationIndex();
      if (currentIndex != animationIndexWalk &&
          currentIndex != animationIndexAttack &&
          currentIndex != animationIndexHurt) {
        if (animationIndexWalk < animationList.length) {
          animation = animationList[animationIndexWalk];
        }
      }
    } else {
      // 距离为0，播放待机动画
      final currentIndex = getCurrentAnimationIndex();
      if (currentIndex != animationIndexIdle &&
          currentIndex != animationIndexAttack &&
          currentIndex != animationIndexHurt) {
        if (animationIndexIdle < animationList.length) {
          animation = animationList[animationIndexIdle];
        }
      }
    }
  }

  /// 更新朝向：根据与玩家的相对位置翻转敌人
  void updateFacingDirection() {
    final directionToPlayer = playerRef.position.x - position.x;

    // 玩家在右边，敌人面向右
    if (directionToPlayer > 0) {
      scale.x = 1;
    }
    // 玩家在左边，敌人面向左
    else if (directionToPlayer < 0) {
      scale.x = -1;
    }
  }

  // ============ 攻击相关方法 ============

  /// 播放攻击动画
  void playAttack() {
    // 检查攻击冷却
    final now = DateTime.now();
    if (lastAttackTime != null) {
      final cooldownElapsed =
          now.difference(lastAttackTime!).inMilliseconds;
      if (cooldownElapsed < config.attackCooldownMs) {
        return;
      }
    }

    // 如果正在播放其他动画，不打断
    final currentIndex = getCurrentAnimationIndex();
    if (currentIndex == animationIndexAttack ||
        currentIndex == animationIndexHurt) {
      return;
    }

    isAttacking = true;
    lastAttackTime = now;
    attackStartTime = now;

    // 播放攻击动画
    if (animationIndexAttack < animationList.length) {
      animation = animationList[animationIndexAttack];
    }
  }

  /// 检查攻击动画是否完成
  void checkAttackAnimationCompletion() {
    if (attackStartTime == null) {
      isAttacking = false;
      return;
    }

    final currentIndex = getCurrentAnimationIndex();

    // 如果当前不是攻击动画，标记为完成
    if (currentIndex != animationIndexAttack) {
      isAttacking = false;
      return;
    }

    // 计算攻击动画的时长
    final attackDuration = animationIndexAttack < frameList.length
        ? frameList[animationIndexAttack] * animationStepTime
        : 0.5; // 默认0.5秒

    // 检查攻击动画是否已经完成
    final timeSinceAttackStart =
        DateTime.now().difference(attackStartTime!).inMilliseconds;
    final attackDurationMs = (attackDuration * 1000).round();

    if (timeSinceAttackStart >= attackDurationMs) {
      isAttacking = false;
      attackStartTime = null;

      // 切换到待机动画，下一帧会根据距离决定是移动还是继续攻击
      if (animationIndexIdle < animationList.length) {
        animation = animationList[animationIndexIdle];
      }
    }
  }

  // ============ 受伤和死亡 ============

  /// 受到伤害
  void takeDamage(int damage) {
    if (isDead) {
      return;
    }

    currentHealth -= damage;

    if (currentHealth <= 0) {
      die();
    } else {
      playHurt();
    }
  }

  /// 播放受伤动画
  void playHurt() {
    final currentIndex = getCurrentAnimationIndex();
    if (currentIndex == animationIndexHurt ||
        currentIndex == animationIndexDeath) {
      return;
    }

    if (animationIndexHurt < animationList.length) {
      animation = animationList[animationIndexHurt];
    }

    // 受伤动画播放完成后恢复
    Future.delayed(
      Duration(
        milliseconds: animationIndexHurt < frameList.length
            ? (frameList[animationIndexHurt] * animationStepTime * 1000).round()
            : 300,
      ),
      () {
        if (!isDead && animationIndexIdle < animationList.length) {
          animation = animationList[animationIndexIdle];
        }
      },
    );
  }

  /// 死亡
  void die() {
    if (isDead) {
      return;
    }

    isDead = true;
    isAttacking = false;
    if (animationIndexDeath < animationList.length) {
      animation = animationList[animationIndexDeath];
    }

    // 死亡动画播放完成后移除组件
    Future.delayed(
      Duration(
        milliseconds: animationIndexDeath < frameList.length
            ? (frameList[animationIndexDeath] * animationStepTime * 1000)
                .round()
            : 1000,
      ),
      () {
        removeFromParent();
      },
    );
  }

  // ============ 动画加载方法 ============

  /// 加载所有动画资源
  Future<void> loadAnimations() async {
    animationList = [];
    frameList = [];

    for (int i = 0; i < config.actionNames.length; i++) {
      final actionName = config.actionNames[i];

      // 尝试加载图片，统计帧数
      final frames = <Sprite>[];
      int frameCount = 0;
      bool hasFrame = true;

      while (hasFrame) {
        frameCount++;
        try {
          final image = await gameRef.images.load(
            '${config.name}/${actionName}$frameCount.png',
          );
          // 使用实际图片尺寸，而不是预设的frameSize
          final sprite = Sprite(
            image,
            srcSize: Vector2(image.width.toDouble(), image.height.toDouble()),
            srcPosition: Vector2.zero(),
          );
          frames.add(sprite);
        } catch (e) {
          // 捕获异常但不抛出，停止加载这个动画的帧
          hasFrame = false;
          frameCount--;
          break;
        }

        // 限制最大帧数，避免无限循环
        if (frameCount >= 30) {
          hasFrame = false;
        }
      }
      
      // 如果找到了至少一帧，就使用这些帧创建动画
      if (frames.isNotEmpty) {
        final animation = SpriteAnimation.spriteList(
          frames,
          stepTime: animationStepTime,
          loop: config.animationLoops[i],
        );
        animationList.add(animation);
        frameList.add(frameCount);
        continue; // 继续下一个动画
      }

      // 如果没有找到任何帧，使用占位动画
      if (frames.isEmpty) {
        // 如果是第一个动画（Idle）且没有帧，尝试加载Idle1作为占位
        if (i == 0) {
          try {
            final placeholderImage = await gameRef.images.load(
              '${config.name}/${config.actionNames[0]}1.png',
            );
            final placeholderSprite = Sprite(
              placeholderImage,
              srcSize: Vector2(
                placeholderImage.width.toDouble(),
                placeholderImage.height.toDouble(),
              ),
              srcPosition: Vector2.zero(),
            );
            animationList.add(SpriteAnimation.spriteList(
              [placeholderSprite],
              stepTime: animationStepTime,
              loop: config.animationLoops[i],
            ));
            frameList.add(1);
          } catch (e) {
            // 如果连占位符都加载不了，跳过这个动画
            // 这会导致后续动画也无法使用，但至少不会崩溃
            continue;
          }
        } else {
          // 使用Idle动画作为占位
          if (animationList.isNotEmpty) {
            animationList.add(animationList[animationIndexIdle]);
            frameList.add(frameList[animationIndexIdle]);
          } else {
            // 如果连Idle都没有，跳过这个动画
            continue;
          }
        }
      }
    }

    // 根据第一帧的实际尺寸调整敌人的显示尺寸
    if (animationList.isNotEmpty && animationList[animationIndexIdle].frames.isNotEmpty) {
      final firstFrame = animationList[animationIndexIdle].frames[0];
      final sprite = firstFrame.sprite;
      
      // 根据实际图片尺寸调整敌人组件的显示尺寸
      final imageWidth = sprite.image.width.toDouble();
      final imageHeight = sprite.image.height.toDouble();
      
      // 对于demon和lizard，使用实际尺寸
      // 对于其他敌人，如果图片较大则适当缩小
      if (enemyType == EnemyType.demon || enemyType == EnemyType.lizard) {
        size = Vector2(imageWidth, imageHeight);
      } else {
        // 限制最大尺寸为200，保持宽高比
        final maxWidth = imageWidth.clamp(0, 200);
        final scaleFactor = maxWidth / imageWidth;
        size = Vector2(
          imageWidth * scaleFactor,
          imageHeight * scaleFactor,
        );
      }
    }
  }

  /// 初始化敌人：设置初始动画和朝向
  void initializeEnemy() {
    if (animationList.isNotEmpty && animationIndexIdle < animationList.length) {
      animation = animationList[animationIndexIdle];
    }
    scale.x = -1; // 初始朝向为向左（面向玩家）
  }

  // ============ 工具方法 ============

  /// 获取当前动画的索引
  int getCurrentAnimationIndex() {
    if (animation == null || animationList.isEmpty) {
      return -1;
    }
    return animationList.indexOf(animation!);
  }
}
