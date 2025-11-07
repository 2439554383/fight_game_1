import 'package:flutter/material.dart';
import 'package:get/get.dart';

const testAvatar =
    "https://www.google.com/url?sa=i&url=https%3A%2F%2F699pic.com%2Fimage%2Fkejiganyouxitouxiang.html&psig=AOvVaw1OKftjvVHz79nHQ-CFp_eU&ust=1761908428220000&source=images&cd=vfe&opi=89978449&ved=0CBUQjRxqFwoTCIi3t8jiy5ADFQAAAAAdAAAAABAE";

void showToast(String message) {
  Get.snackbar(
    '',
    message,
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: Colors.black87,
    colorText: Colors.white,
    messageText: Text(message, style: const TextStyle(color: Colors.white)),
    duration: const Duration(seconds: 2),
    margin: const EdgeInsets.all(10),
  );
}

myAvatar({required String url, required double width, required double height}) {
  return ClipOval(
    child: nImage(url: url, width: width, height: height),
  );
}

// aImage({
//   required String imageName,
//   required double width,
//   required double height,
// }) {
//   return imageName == ""
//       ? Placeholder(fallbackWidth: width, fallbackHeight: height)
//       : Image.asset(
//           "assets/images/imageName.png",
//           width: width,
//           height: height,
//           fit: BoxFit.cover,);
// }
//
nImage({required String url, required double width, required double height}) {
  return url == ""
      ? Placeholder(fallbackWidth: width, fallbackHeight: height)
      : Image.network(url, width: width, height: height, fit: BoxFit.cover);
}

class PublicWidget {
  PublicWidget();
}
