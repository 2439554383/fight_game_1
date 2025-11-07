import 'package:get/get.dart';
import '../page/main_page.dart';
import '../page/main_page_ctrl.dart';
import '../page/game/start_game.dart';
import '../page/game/start_game_ctrl.dart';

class FRoute {
  static const String mainPage = '/main_page';
  static const String game = '/game';
  static const String startGame = '/start_game';

  static push(
    String name, {
    arguments,
    Function(dynamic)? result,
    bool? preventDuplicates,
  }) {
    Get.toNamed(
      name,
      arguments: arguments,
      preventDuplicates: preventDuplicates != null ? preventDuplicates : true,
    )?.then((value) {
      result?.call(value);
    });
  }

  static offAndToNamed(String name, {arguments, Function? result}) {
    Get.offAndToNamed(name, arguments: arguments)?.then((value) {
      result?.call(value);
    });
  }

  static offAll(String name, {arguments}) {
    // Get.offAllNamed(name);
    Get.offNamedUntil(name, (route) => false, arguments: arguments);
  }
}

class AppPages {
  static final List<GetPage> routes = [
    GetPage(
      name: FRoute.mainPage,
      page: () => MainPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => MainPageCtrl());
      }),
    ),

    GetPage(
      name: FRoute.startGame,
      page: () => StartGame(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => StartGameCtrl());
      }),
    ),
  ];
}
