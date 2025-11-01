import 'package:flame/camera.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/static/font_style.dart';
import 'package:untitled1/util/app_component.dart';

import 'audio/audio_controller.dart';
import 'background/background_ctrl.dart';
import 'my_world/my_world_ctrl.dart';
import 'start_game_ctrl.dart';

// 自定义Game类，支持键盘输入
class MyGame extends FlameGame with HasKeyboardHandlerComponents {
  MyGame({this.audioController}) : super(
    world: MyWorld(),
    // 设置固定分辨率视口，解决背景图片显示问题（参考项目方式）
    camera: CameraComponent.withFixedResolution(width: 1920.w, height: 1080.h),
  );
  
  final AudioController? audioController;
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // 添加视差滚动背景（Flame推荐方式）
    final myWorld = world as MyWorld;
    camera.backdrop.add(Background(speed: 0));
    
    // 播放背景音乐（如果有音频控制器）
    // 延迟播放，确保游戏完全加载后再播放音乐
    Future.delayed(const Duration(milliseconds: 500), () {
      audioController?.playBackgroundMusic('audio/tropical_fantasy.mp3');
    });
  }
  
  @override
  void onRemove() {
    // 游戏结束时停止背景音乐
    audioController?.stopBackgroundMusic();
    super.onRemove();
  }
}

class StartGame extends GetView<StartGameCtrl> {
  final PublicWidget pW = PublicWidget();
  final MyFont myFont = MyFont();
  final AudioController _audioController = AudioController();
  
  StartGame({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<StartGameCtrl>(
      init: StartGameCtrl(),
      builder: (ctrl) => Scaffold(
        backgroundColor: Colors.white,
        body: GameWidget(
          game: MyGame(audioController: _audioController),
        ),
      ),
    );
  }
}


