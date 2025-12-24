import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeController extends GetxController {
  final isDarkMode = false.obs;
  final _box = GetStorage();

  @override
  void onInit() {
    isDarkMode.value = _box.read('isDark') ?? false;
    super.onInit();
  }

  void toggleTheme() {
    isDarkMode.toggle();
    _box.write('isDark', isDarkMode.value);
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }
}
