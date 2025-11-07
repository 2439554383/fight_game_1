import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/static/default.dart';
import 'package:untitled1/static/font_style.dart';
import 'package:untitled1/util/app_component.dart';
import '../util/f_route.dart';
import 'main_page_ctrl.dart';
import 'package:untitled1/gen/assets.gen.dart';

class MainPage extends GetView<MainPageCtrl> {
  late MyFont myFont = MyFont();
  MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MainPageCtrl>(
      init: MainPageCtrl(),
      builder: (ctrl) => Scaffold(
        backgroundColor: Color.fromARGB(250, 13, 0, 73),
        body: Stack(
          children: [
            Assets.images.mainPageBg.image(
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(height: 15.h),
                    topButton(),
                    Spacer(),
                    buildSampleWidget(),
                    SizedBox(height: 70.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget topButton() {
    return Container(
      margin: EdgeInsetsGeometry.symmetric(horizontal: 15.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: () {},
            child: Row(
              children: [
                myAvatar(url: FDefault().avatar, width: 45.w, height: 45.h),
                SizedBox(width: 5.w),
                Text("我的"),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            child: Icon(Icons.settings, size: 30.sp),
          ),
        ],
      ),
    );
  }

  Widget buildSampleWidget() {
    return ElevatedButton(
      onPressed: () {
        FRoute.push(FRoute.startGame);
      },
      style: ButtonStyle(
        padding: WidgetStatePropertyAll(
          EdgeInsetsGeometry.symmetric(horizontal: 65.w, vertical: 30.h),
        ),
      ),
      child: Text("开始游戏", style: myFont.black_4_18),
    );
  }
}
