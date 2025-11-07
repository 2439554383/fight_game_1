import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class StartGameCtrl extends GetxController {
  double bloodVolume = 300.w;

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onClose() {
    super.onClose();
  }

  changeBlood(){
    bloodVolume-=0.1;
    update();
  }
}
