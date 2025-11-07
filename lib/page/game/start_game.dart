import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart' hide PointerMoveEvent;
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

  void handleAnalogDirection(Vector2 direction) {
    final currentPlayer = player;
    if (currentPlayer == null || !currentPlayer.isMounted) {
      return;
    }
    currentPlayer.handleAnalogDirection(direction);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (size.x <= 0 || size.y <= 0) {
      return;
    }
    camera.viewport = FixedResolutionViewport(resolution: size);
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
          Positioned.fill(child: GameWidget(game: _game)),
          Positioned(
            left: 50.w,
            top: 50.h,
            child: GetBuilder<StartGameCtrl>(
              builder: (ctrl) => Row(
                children: [
                  Text("武士长官", style: myFont.white_4_25),
                  SizedBox(width: 10.w),
                  Container(
                    width: 300.w,
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
            child: _VirtualJoystick(onChanged: _onAnalogDirectionChanged),
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

  void _onAnalogDirectionChanged(Vector2 direction) {
    _game.handleAnalogDirection(direction);
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
    final double buttonSize = 129.w;
    final double spacing = 27.w;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _VirtualActionButton(
          label: '攻',
          size: buttonSize,
          onPressed: onAttack,
          onReleased: onAttackRelease,
        ),
        SizedBox(width: spacing),
        _VirtualActionButton(
          label: '防',
          size: buttonSize,
          onPressed: onGuard,
          onReleased: onGuardRelease,
        ),
        SizedBox(width: spacing),
        _VirtualActionButton(
          label: '跳',
          size: buttonSize,
          onPressed: onJump,
          onReleased: onJumpRelease,
        ),
      ],
    );
  }
}

class _VirtualActionButton extends StatefulWidget {
  const _VirtualActionButton({
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
  State<_VirtualActionButton> createState() => _VirtualActionButtonState();
}

class _VirtualActionButtonState extends State<_VirtualActionButton> {
  bool _isPressed = false;

  void _handleDown(PointerDownEvent event) {
    if (_isPressed) {
      return;
    }
    setState(() => _isPressed = true);
    widget.onPressed();
  }

  void _handleUp(PointerUpEvent event) {
    if (!_isPressed) {
      return;
    }
    setState(() => _isPressed = false);
    widget.onReleased();
  }

  void _handleCancel(PointerCancelEvent event) {
    if (!_isPressed) {
      return;
    }
    setState(() => _isPressed = false);
    widget.onReleased();
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle textStyle = Theme.of(context).textTheme.titleMedium!
        .copyWith(color: Colors.white, fontWeight: FontWeight.w600);

    return Listener(
      onPointerDown: _handleDown,
      onPointerUp: _handleUp,
      onPointerCancel: _handleCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: _isPressed
              ? Colors.white.withOpacity(0.35)
              : Colors.black.withOpacity(0.35),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: Colors.white.withOpacity(0.7), width: 2),
        ),
        alignment: Alignment.center,
        child: Transform.scale(
          scale: _isPressed ? 0.92 : 1.0,
          child: Text(widget.label, style: textStyle),
        ),
      ),
    );
  }
}

class _VirtualJoystick extends StatefulWidget {
  const _VirtualJoystick({required this.onChanged});

  final ValueChanged<Vector2> onChanged;

  @override
  State<_VirtualJoystick> createState() => _VirtualJoystickState();
}

class _VirtualJoystickState extends State<_VirtualJoystick> {
  Offset _thumbOffset = Offset.zero;
  bool _isActive = false;

  void _onPointerDown(PointerDownEvent event) {
    _updateThumbOffset(event.localPosition);
  }

  void _onPointerMove(PointerMoveEvent event) {
    _updateThumbOffset(event.localPosition);
  }

  void _onPointerUp(PointerUpEvent event) {
    _resetJoystick();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _resetJoystick();
  }

  void _resetJoystick() {
    if (!_isActive && _thumbOffset == Offset.zero) {
      return;
    }
    setState(() {
      _thumbOffset = Offset.zero;
      _isActive = false;
    });
    widget.onChanged(Vector2.zero());
  }

  void _updateThumbOffset(Offset position) {
    final Size? boxSize = context.size;
    if (boxSize == null) {
      return;
    }

    final Offset center = Offset(boxSize.width / 2, boxSize.height / 2);
    final Offset delta = position - center;
    final double radius = boxSize.width / 2;
    if (radius <= 0) {
      return;
    }

    Offset clamped = delta;
    if (delta.distance > radius) {
      clamped = Offset.fromDirection(delta.direction, radius);
    }

    setState(() {
      _thumbOffset = clamped;
      _isActive = true;
    });

    final Vector2 direction = Vector2(clamped.dx / radius, clamped.dy / radius);
    widget.onChanged(direction);
  }

  @override
  Widget build(BuildContext context) {
    final double size = 220.w;

    return SizedBox(
      width: size,
      height: size,
      child: Listener(
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerCancel,
        behavior: HitTestBehavior.opaque,
        child: CustomPaint(
          painter: _JoystickPainter(
            thumbOffset: _thumbOffset,
            isActive: _isActive,
          ),
        ),
      ),
    );
  }
}

class _JoystickPainter extends CustomPainter {
  _JoystickPainter({required this.thumbOffset, required this.isActive});

  final Offset thumbOffset;
  final bool isActive;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2;

    final Paint basePaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final Paint borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final Paint thumbPaint = Paint()
      ..color = isActive
          ? Colors.white.withOpacity(0.45)
          : Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, basePaint);
    canvas.drawCircle(center, radius, borderPaint);

    final Offset thumbCenter = center + thumbOffset;
    canvas.drawCircle(thumbCenter, radius * 0.35, thumbPaint);
  }

  @override
  bool shouldRepaint(covariant _JoystickPainter oldDelegate) {
    return oldDelegate.thumbOffset != thumbOffset ||
        oldDelegate.isActive != isActive;
  }
}
