import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/gen/assets.gen.dart';
import 'package:untitled1/static/font_style.dart';
import 'package:untitled1/util/app_component.dart';

import 'game_ctrl.dart';

class Game extends GetView<GameCtrl> {
  final PublicWidget pW = PublicWidget();
  final MyFont myFont = MyFont();
  Game({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<GameCtrl>(
      init: GameCtrl(),
      builder: (ctrl) => Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Assets.images.gameBg.image(width: double.infinity,height: double.infinity,fit: BoxFit.cover),
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    buildGameWidget(),
                  ],
                ),
              ),
            ),
            Positioned(
                top: 35.h,
                left: 45.w,
                child: GestureDetector(
                  onTap: (){
                    Get.back();
                  },
                  child: Icon(Icons.arrow_back,color: Colors.white,size: 55.sp,),
                )
            )
          ],
        ),
      ),
    );
  }

  Widget buildGameWidget() {
    return Container(
      child: Text("data"),
    );
  }
}

