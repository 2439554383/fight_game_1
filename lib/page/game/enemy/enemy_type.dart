/// 敌人类型枚举
enum EnemyType {
  demon,
  dragon,
  jinnAnimation,
  lizard,
  medusa,
  smallDragon,
}

/// 敌人类型配置
class EnemyTypeConfig {
  /// 敌人类型名称（用于加载资源）
  final String name;

  /// 敌人移动速度（像素/秒）
  final double moveSpeed;

  /// 敌人攻击距离
  final double attackRange;

  /// 敌人攻击冷却时间（毫秒）
  final int attackCooldownMs;

  /// 敌人健康值
  final int health;

  /// 敌人动画名称列表
  final List<String> actionNames;

  /// 敌人动画循环列表
  final List<bool> animationLoops;

  const EnemyTypeConfig({
    required this.name,
    required this.moveSpeed,
    required this.attackRange,
    required this.attackCooldownMs,
    required this.health,
    required this.actionNames,
    required this.animationLoops,
  });

  /// 获取敌人类型配置
  static EnemyTypeConfig getConfig(EnemyType type) {
    switch (type) {
      case EnemyType.demon:
        return const EnemyTypeConfig(
          name: 'demon',
          moveSpeed: 80.0,
          attackRange: 150.0,
          attackCooldownMs: 1500,
          health: 100,
          actionNames: [
            'Idle',
            'Walk',
            'Attack',
            'Hurt',
            'Death',
          ],
          animationLoops: [
            true,  // Idle: 循环
            true,  // Walk: 循环
            false, // Attack: 不循环
            false, // Hurt: 不循环
            false, // Death: 不循环
          ],
        );
      case EnemyType.dragon:
        return const EnemyTypeConfig(
          name: 'dragon',
          moveSpeed: 60.0,
          attackRange: 200.0,
          attackCooldownMs: 2000,
          health: 200,
          actionNames: [
            'Idle',
            'Walk',
            'Attack',
            'Fire_Attack',
            'Hurt',
            'Death',
          ],
          animationLoops: [
            true,  // Idle: 循环
            true,  // Walk: 循环
            false, // Attack: 不循环
            false, // Fire_Attack: 不循环
            false, // Hurt: 不循环
            false, // Death: 不循环
          ],
        );
      case EnemyType.jinnAnimation:
        return const EnemyTypeConfig(
          name: 'jinn_animation',
          moveSpeed: 100.0,
          attackRange: 180.0,
          attackCooldownMs: 1800,
          health: 80,
          actionNames: [
            'Idle',
            'Flight',
            'Attack',
            'Magic_Attack',
            'Hurt',
            'Death',
          ],
          animationLoops: [
            true,  // Idle: 循环
            true,  // Flight: 循环
            false, // Attack: 不循环
            false, // Magic_Attack: 不循环
            false, // Hurt: 不循环
            false, // Death: 不循环
          ],
        );
      case EnemyType.lizard:
        return const EnemyTypeConfig(
          name: 'lizard',
          moveSpeed: 90.0,
          attackRange: 140.0,
          attackCooldownMs: 1200,
          health: 70,
          actionNames: [
            'Idle',
            'Walk',
            'Attack',
            'Hurt',
            'Death',
          ],
          animationLoops: [
            true,  // Idle: 循环
            true,  // Walk: 循环
            false, // Attack: 不循环
            false, // Hurt: 不循环
            false, // Death: 不循环
          ],
        );
      case EnemyType.medusa:
        return const EnemyTypeConfig(
          name: 'medusa',
          moveSpeed: 70.0,
          attackRange: 160.0,
          attackCooldownMs: 1700,
          health: 120,
          actionNames: [
            'Idle',
            'Walk',
            'Attack',
            'Stone',
            'Hurt',
            'Death',
          ],
          animationLoops: [
            true,  // Idle: 循环
            true,  // Walk: 循环
            false, // Attack: 不循环
            false, // Stone: 不循环
            false, // Hurt: 不循环
            false, // Death: 不循环
          ],
        );
      case EnemyType.smallDragon:
        return const EnemyTypeConfig(
          name: 'small_dragon',
          moveSpeed: 85.0,
          attackRange: 170.0,
          attackCooldownMs: 1400,
          health: 90,
          actionNames: [
            'Idle',
            'Walk',
            'Attack',
            'Fire_Attack',
            'Hurt',
            'Death',
          ],
          animationLoops: [
            true,  // Idle: 循环
            true,  // Walk: 循环
            false, // Attack: 不循环
            false, // Fire_Attack: 不循环
            false, // Hurt: 不循环
            false, // Death: 不循环
          ],
        );
    }
  }
}
