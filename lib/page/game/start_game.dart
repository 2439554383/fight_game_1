import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/static/font_style.dart';
import 'package:untitled1/util/app_component.dart';

import 'my_world/my_world_ctrl.dart';
import 'start_game_ctrl.dart';

class StartGame extends GetView<StartGameCtrl> {
  final PublicWidget pW = PublicWidget();
  final MyFont myFont = MyFont();
  StartGame({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<StartGameCtrl>(
      init: StartGameCtrl(),
      builder: (ctrl) => Scaffold(
        backgroundColor: Colors.white,
        body: GameWidget(game: FlameGame(world: MyWorld())),
      ),
    );
  }
}


