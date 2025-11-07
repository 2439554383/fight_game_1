import 'dart:math';

import 'package:flame/components.dart';

import '../player/player_ctrl.dart';
import 'enemy_ctrl.dart';
import 'enemy_type.dart';

/// 敌人管理器
/// 负责生成、管理和销毁敌人
class EnemyManager extends Component with HasGameRef {
  EnemyManager({
    required this.playerRef,
    this.spawnInterval = 3.0,
    this.maxEnemies = 10,
    this.spawnDistance = 800.0,
  });

  /// 玩家引用
  final Player playerRef;

  /// 敌人生成间隔（秒）
  final double spawnInterval;

  /// 最大敌人数量
  final int maxEnemies;

  /// 生成距离（距离玩家的距离）
  final double spawnDistance;

  /// 所有敌人列表
  final List<Enemy> enemies = [];

  /// 上次生成时间（使用累加时间）
  double lastSpawnTime = 0.0;

  /// 当前时间（累加update中的dt）
  double currentTime = 0.0;

  /// 所有敌人类型
  static final List<EnemyType> allEnemyTypes = EnemyType.values;

  /// 随机数生成器
  final Random _random = Random();

  @override
  void update(double dt) {
    super.update(dt);

    // 累加时间
    currentTime += dt;

    // 清理已死亡的敌人
    enemies.removeWhere((enemy) => enemy.isDead || !enemy.isMounted);

    // 检查是否需要生成新敌人
    if (currentTime - lastSpawnTime >= spawnInterval) {
      if (enemies.length < maxEnemies) {
        spawnEnemy();
        lastSpawnTime = currentTime;
      }
    }
  }

  /// 生成一个敌人
  void spawnEnemy() {
    // 随机选择敌人类型
    final enemyType =
        allEnemyTypes[_random.nextInt(allEnemyTypes.length)];

    // 计算生成位置（在玩家前方一定距离，随机Y偏移）
    final spawnPosition = calculateSpawnPosition();

    // 创建敌人
    final enemy = Enemy(
      enemyType: enemyType,
      playerRef: playerRef,
      position: spawnPosition,
    );

    // 添加到世界和列表
    parent?.add(enemy);
    enemies.add(enemy);
  }

  /// 计算敌人生成位置
  /// 在玩家前方一定距离，Y坐标随机偏移
  /// 随着玩家移动，敌人会在玩家前方生成
  Vector2 calculateSpawnPosition() {
    final gameSize = gameRef.size;
    final playerPos = playerRef.position;

    // 生成在玩家前方的X位置（玩家右侧）
    // 增加一些随机性，让敌人在一个范围内生成
    final randomXOffset = _random.nextDouble() * 200 - 100;
    final spawnX = playerPos.x + spawnDistance + randomXOffset;

    // Y坐标随机（在屏幕范围内，并有一些随机偏移）
    final randomYOffset = _random.nextDouble() * 400 - 200;
    final spawnY = playerPos.y + randomYOffset;

    // 确保Y坐标在合理范围内（相对于玩家位置）
    // 允许敌人在玩家上下一定范围内生成
    final clampedY = spawnY.clamp(
      playerPos.y - gameSize.y / 2,
      playerPos.y + gameSize.y / 2,
    );

    return Vector2(spawnX, clampedY);
  }

  /// 批量生成敌人
  void spawnEnemies(int count) {
    for (int i = 0; i < count; i++) {
      spawnEnemy();
    }
  }

  /// 清除所有敌人
  void clearAllEnemies() {
    for (final enemy in enemies) {
      enemy.removeFromParent();
    }
    enemies.clear();
  }

  /// 获取当前敌人数量
  int get enemyCount => enemies.length;
}
