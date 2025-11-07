import 'dart:math';

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';

import '../background/background_ctrl.dart';
import '../enemy/enemy_manager.dart';
import '../player/player_ctrl.dart';
import '../start_game.dart';

class MyWorld extends World with TapCallbacks {
  late Player player;
  late EnemyManager enemyManager;

  // 添加 speed getter
  double get speed => 100.0; // 可以根据需要调整速度值

  // 添加 size getter
  Vector2 get size => (parent as FlameGame).size;

  /// 获取背景组件
  Background? get background {
    final game = parent;
    if (game is MyGame) {
      return game.background;
    }
    return null;
  }

  @override
  Future<void> onLoad() async {
    player = Player(position: Vector2(0, 0));
    add(player);

    // 创建敌人管理器
    enemyManager = EnemyManager(
      playerRef: player,
      spawnInterval: 3.0, // 每3秒生成一个敌人
      maxEnemies: 15, // 最大15个敌人
      spawnDistance: 800.0, // 在玩家前方800像素生成
    );
    add(enemyManager);

    // 初始生成几个敌人
    enemyManager.spawnEnemies(3);

    // 初始化相机位置为玩家位置
    final game = parent as FlameGame;
    game.camera.viewfinder.anchor = Anchor.center;
    game.camera.viewfinder.position = player.position;
  }

  /// 获取相机引用
  CameraComponent? get camera {
    final game = parent;
    if (game is FlameGame) {
      return game.camera;
    }
    return null;
  }

  /// 获取屏幕宽度
  double get screenWidth {
    final game = parent;
    if (game is FlameGame) {
      return game.size.x;
    }
    return 1920; // 默认值
  }

  /// 玩家在屏幕中的相对位置（0=左边缘，1=右边缘）
  double get playerScreenPosition {
    final cam = camera;
    if (cam == null) return 0.5;
    
    // 计算玩家相对于相机的位置（世界坐标转屏幕坐标）
    final playerWorldX = player.position.x;
    final cameraWorldX = cam.viewfinder.position.x;
    
    // 玩家在屏幕中的X坐标（相对于屏幕左边缘）
    final playerScreenX = playerWorldX - cameraWorldX + screenWidth / 2;
    
    // 转换为0-1的相对位置
    return playerScreenX / screenWidth;
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Player的update已经执行完成，现在检查Player的屏幕位置
    final cam = camera;
    if (cam == null) return;
    
    // 计算玩家在当前帧移动后的屏幕位置
    final screenPos = playerScreenPosition;
    
    // 屏幕滚动阈值：当玩家移动到屏幕的2/3位置时，相机开始跟随
    const scrollThreshold = 2.0 / 3.0;
    
    // 计算相机需要移动的距离
    double cameraMoveX = 0;
    double backgroundSpeed = 0;
    bool shouldMoveCamera = false;
    
    // 玩家向右移动（按D键）
    if (player.currentMoveDirection.x > 0) {
      // 如果玩家超过阈值位置，相机跟随
      if (screenPos > scrollThreshold) {
        shouldMoveCamera = true;
        final playerSpeedX = player.currentMoveDirection.x * Player.moveSpeed;
        // 相机移动速度等于玩家移动速度
        cameraMoveX = playerSpeedX * dt;
        // 背景滚动速度设为玩家移动速度的100%（完全跟随）
        backgroundSpeed = playerSpeedX;
      }
    }
    // 玩家向左移动（按A键）
    else if (player.currentMoveDirection.x < 0) {
      // 如果玩家在屏幕左侧1/3区域，相机跟随
      if (screenPos < (1 - scrollThreshold)) {
        shouldMoveCamera = true;
        final playerSpeedX = player.currentMoveDirection.x * Player.moveSpeed;
        // 相机移动速度等于玩家移动速度
        cameraMoveX = playerSpeedX * dt;
        // 背景滚动速度设为玩家移动速度的100%（完全跟随）
        backgroundSpeed = playerSpeedX;
      }
    }
    
    // 如果相机需要移动
    if (shouldMoveCamera && cameraMoveX != 0) {
      // 移动相机
      cam.viewfinder.position.x += cameraMoveX;
      
      // 更新背景滚动
      background?.updateSpeed(backgroundSpeed);
    } else {
      // 相机不移动时，背景也不滚动
      background?.updateSpeed(0);
    }
    
    // 注意：Player在世界坐标中的移动保持不变
    // 敌人也保持在世界坐标中的位置不变
    // 相机移动时，由于玩家和敌人的世界坐标不变，它们会随着相机移动而在屏幕上移动
    // 但玩家的世界坐标实际上在增加（因为Player.update已经执行），所以玩家会前进
    // 相机的移动抵消了玩家在屏幕上的移动，使得玩家保持在阈值位置附近
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
