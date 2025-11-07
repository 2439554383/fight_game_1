import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/page/game/player/player_ctrl.dart';
import 'package:untitled1/static/font_style.dart';
import 'package:untitled1/util/app_component.dart';

import 'audio/audio_controller.dart';
import 'background/background_ctrl.dart';
import 'my_world/my_world_ctrl.dart';
import 'start_game_ctrl.dart';

// 自定义Game类，支持键盘输入
class MyGame extends FlameGame
    with HasKeyboardHandlerComponents, HasCollisionDetection {
  MyGame({this.audioController})
    : super(
        world: MyWorld(),
        camera: CameraComponent.withFixedResolution(width: 1920, height: 1080),
      );

  final AudioController? audioController;

  /// 背景组件引用
  Background? background;

  Player? get player {
    final currentWorld = world;
    if (currentWorld is! MyWorld) {
      return null;
    }
    try {
      return currentWorld.player;
    } on Exception catch (e) {
        return null;
    }

    // on LateInitializationError {
    //   return null;
    // }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // 添加视差滚动背景（Flame推荐方式）
    background = Background(speed: 0);
    camera.backdrop.add(background!);
    // addLifeBar();
    // 播放背景音乐（如果有音频控制器）
    // 延迟播放，确保游戏完全加载后再播放音乐
    // Future.delayed(const Duration(milliseconds: 500), () {
    //   // Flame 音频系统会自动在 assets/audio/ 目录下查找文件
    //   audioController?.playBackgroundMusic('tropical_fantasy.mp3');
    // });
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    super.onKeyEvent(event, keysPressed);
    if (event is KeyDownEvent) {
      if (keysPressed.contains(LogicalKeyboardKey.keyP)) {
        addPlayerFromGame();
      }
    }
    return KeyEventResult.handled;
  }

  void addPlayerFromGame() {
    // world 是 Game 的属性，指向 MyWorld
    final newPlayer = Player(position: Vector2(0, 0));
    world.add(newPlayer); // 直接添加到world
  }

  void addLifeBar() {
    world.add(
      RectangleComponent(
        position: Vector2(10.0, 15.0),
        size: Vector2(200, 10), // 宽度10，高度200（竖条）
        angle: 0, // 不旋转
        paint: Paint()..color = Colors.green,
        anchor: Anchor.topLeft,
      ),
    );
  }

  @override
  void onRemove() {
    // 游戏结束时停止背景音乐
    audioController?.stopBackgroundMusic();
    super.onRemove();
  }

  void handleVirtualKey(LogicalKeyboardKey key, bool isPressed) {
    final currentPlayer = player;
    if (currentPlayer == null || !currentPlayer.isMounted) {
      return;
    }
    if (isPressed) {
      currentPlayer.handleVirtualKeyDown(key);
    } else {
      currentPlayer.handleVirtualKeyUp(key);
    }
  }
}

class StartGame extends GetView<StartGameCtrl> {
  final PublicWidget pW = PublicWidget();
  final MyFont myFont = MyFont();
  final AudioController _audioController = AudioController();
  late final MyGame _game = MyGame(audioController: _audioController);

  StartGame({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          GameWidget(game: _game),
          Positioned(
            left: 50.w,
            top: 50.h,
            child: GetBuilder<StartGameCtrl>(
              builder: (ctrl) => Row(
                children: [
                  Text("武士长官", style: myFont.white_4_18),
                  SizedBox(width: 10.w),
                  Container(
                    width: 200.w,
                    height: 45.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Row(
                      children: [
                        Container(width: ctrl.bloodVolume, color: Colors.green),
                        Expanded(child: Container(color: Colors.black)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 48.w,
            bottom: 72.h,
            child: _DirectionalPad(onKeyChange: _onVirtualKeyChange),
          ),
          Positioned(
            right: 48.w,
            bottom: 72.h,
            child: _ActionButtons(
              onAttack: () => _onVirtualButtonPressed(LogicalKeyboardKey.keyJ),
              onAttackRelease: () =>
                  _onVirtualButtonReleased(LogicalKeyboardKey.keyJ),
              onJump: () => _onVirtualButtonPressed(LogicalKeyboardKey.space),
              onJumpRelease: () =>
                  _onVirtualButtonReleased(LogicalKeyboardKey.space),
              onGuard: () => _onVirtualButtonPressed(LogicalKeyboardKey.keyK),
              onGuardRelease: () =>
                  _onVirtualButtonReleased(LogicalKeyboardKey.keyK),
            ),
          ),
        ],
      ),
    );
  }

  void _onVirtualKeyChange(LogicalKeyboardKey key, bool isPressed) {
    _game.handleVirtualKey(key, isPressed);
  }

  void _onVirtualButtonPressed(LogicalKeyboardKey key) {
    _onVirtualKeyChange(key, true);
  }

  void _onVirtualButtonReleased(LogicalKeyboardKey key) {
    _onVirtualKeyChange(key, false);
  }
}

class _DirectionalPad extends StatelessWidget {
  const _DirectionalPad({required this.onKeyChange});

  final void Function(LogicalKeyboardKey key, bool isPressed) onKeyChange;

  @override
  Widget build(BuildContext context) {
    final double buttonSize = 82.w;
    final double spacing = 16.w;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: buttonSize + spacing),
            _VirtualControlButton(
              label: '上',
              size: buttonSize,
              onPressed: () => onKeyChange(LogicalKeyboardKey.keyW, true),
              onReleased: () => onKeyChange(LogicalKeyboardKey.keyW, false),
            ),
          ],
        ),
        SizedBox(height: spacing),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _VirtualControlButton(
              label: '左',
              size: buttonSize,
              onPressed: () => onKeyChange(LogicalKeyboardKey.keyA, true),
              onReleased: () => onKeyChange(LogicalKeyboardKey.keyA, false),
            ),
            SizedBox(width: spacing),
            _VirtualControlButton(
              label: '下',
              size: buttonSize,
              onPressed: () => onKeyChange(LogicalKeyboardKey.keyS, true),
              onReleased: () => onKeyChange(LogicalKeyboardKey.keyS, false),
            ),
            SizedBox(width: spacing),
            _VirtualControlButton(
              label: '右',
              size: buttonSize,
              onPressed: () => onKeyChange(LogicalKeyboardKey.keyD, true),
              onReleased: () => onKeyChange(LogicalKeyboardKey.keyD, false),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.onAttack,
    required this.onAttackRelease,
    required this.onJump,
    required this.onJumpRelease,
    required this.onGuard,
    required this.onGuardRelease,
  });

  final VoidCallback onAttack;
  final VoidCallback onAttackRelease;
  final VoidCallback onJump;
  final VoidCallback onJumpRelease;
  final VoidCallback onGuard;
  final VoidCallback onGuardRelease;

  @override
  Widget build(BuildContext context) {
    final double buttonSize = 86.w;
    final double spacing = 18.h;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _VirtualControlButton(
          label: '跳',
          size: buttonSize,
          onPressed: onJump,
          onReleased: onJumpRelease,
        ),
        SizedBox(height: spacing),
        _VirtualControlButton(
          label: '攻',
          size: buttonSize,
          onPressed: onAttack,
          onReleased: onAttackRelease,
        ),
        SizedBox(height: spacing),
        _VirtualControlButton(
          label: '防',
          size: buttonSize,
          onPressed: onGuard,
          onReleased: onGuardRelease,
        ),
      ],
    );
  }
}

class _VirtualControlButton extends StatelessWidget {
  const _VirtualControlButton({
    required this.label,
    required this.onPressed,
    required this.onReleased,
    required this.size,
  });

  final String label;
  final VoidCallback onPressed;
  final VoidCallback onReleased;
  final double size;

  @override
  Widget build(BuildContext context) {
    final TextStyle textStyle = Theme.of(context).textTheme.titleMedium!
        .copyWith(color: Colors.white, fontWeight: FontWeight.w600);

    return Listener(
      onPointerDown: (_) => onPressed(),
      onPointerUp: (_) => onReleased(),
      onPointerCancel: (_) => onReleased(),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
        ),
        alignment: Alignment.center,
        child: Text(label, style: textStyle),
      ),
    );
  }
}
