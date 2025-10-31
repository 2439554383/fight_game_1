import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/page/main_page.dart';
import 'package:untitled1/util/f_util.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(1920, 1080), // Windows端设计尺寸
      minTextAdapt: true,
      ensureScreenSize: true,
      useInheritedMediaQuery: true,
      splitScreenMode: true,
      builder: (context,child){
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Flutter Demo',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
          ),
          home: MainPage(),
          getPages: AppPages.routes,
        );
      },
    );
  }
}
