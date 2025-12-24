import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('settings'.tr),
      ),
      body: ListView(
        children: [
          ListTile(
            onTap: () {
              final currentLang = Get.locale?.languageCode ?? 'en';
              final newLang = currentLang == 'en' ? 'ar' : 'en';

              Get.updateLocale(Locale(newLang));
              GetStorage().write('lang', newLang);

              // For RTL support
              Get.forceAppUpdate();
            },
            title: Text('change language'.tr),
            leading: Icon(Icons.language),
          ),
          ListTile(
            title: Text(
              'App Version:'.tr,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Row(
              children: [
                SizedBox(
                  width: 20,
                ),
                Text(
                  '0.0.1',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
          ListTile(
            title: Text(
              'Contact Us'.tr,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Row(
              children: [
                SizedBox(
                  width: 10,
                ),
                Text(
                  'example@gmail.com',
                  style: TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
          ListTile(
            title: Text(
              'Terms and Conditions'.tr,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Row(
              children: [
                SizedBox(
                  width: 40,
                ),
                Text(
                  '',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
          ListTile(
            onTap: () {
              if (Get.isDarkMode) {
                Get.changeTheme(ThemeData.light());
              } else {
                Get.changeTheme(ThemeData.dark());
              }
            },
            title: Text(
              'Dark Mode',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Row(
              children: [
                SizedBox(
                  width: 40,
                ),
                Text(
                  '',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
