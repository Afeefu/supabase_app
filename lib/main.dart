import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get_storage/get_storage.dart';
import 'package:supabase_app/cart_screen.dart';
import 'package:supabase_app/core/localaization/app_translations.dart';
// import 'package:supabase_app/home_screen.dart';
import 'package:supabase_app/login_page.dart';
import 'package:supabase_app/main_page.dart';
import 'package:supabase_app/shopping_page.dart';
import 'package:supabase_app/supabase_consts.dart';
import 'package:supabase_app/wish_list_screen.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
  );
  await GetStorage.init();
  Stripe.publishableKey =
      'pk_test_51RAGlwI2aMedNqvReeSSdtyKp7e2WDsdbLb6kqx2RxYHvPZkC60mkVRjy2Dlnz6mds6Ha8fH5sNXRR0tBYySC2Hw00PfHlfzP4';
  await Stripe.instance.applySettings();
  runApp(MyApp());
}

////ndk version cahnged , it was 26.3.11579264 , set to 29.0.13113456
class MyApp extends StatelessWidget {
  final box = GetStorage();
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      theme: ThemeData.dark(),
      translations: AppTranslations(),
      locale:
          box.read('lang') != null ? Locale(box.read('lang')) : Locale('en'),
      fallbackLocale: Locale('en'),
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => const LoginPage(),
        '/home': (context) => const ShoppingPage(),
        '/cart': (context) => const CartScreen(),
        '/wishlist': (context) => const WishlistScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        final session = snapshot.data?.session;
        return session?.user == null ? const LoginPage() : const MainPage();
      },
    );
  }
}
