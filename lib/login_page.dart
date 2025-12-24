import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get_storage/get_storage.dart';
import 'package:supabase_app/main_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_product_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;

  Future<void> loginUser() async {
    // Basic validation
    if (emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      setState(() {
        errorMessage = "Please fill in all fields";
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (response.user != null) {
        // Fetch user role from the database
        final userId = response.user!.id;

        try {
          final userData = await Supabase.instance.client
              .from('users')
              .select('role')
              .eq('id', userId)
              .single();

          final isAdmin = userData['role'] == 'admin';

          if (!mounted) return;

          // Navigate based on user role using GetX
          if (isAdmin) {
            Get.offAll(() => AddProductScreen());
          } else {
            Get.offAll(() => MainPage());
          }
        } catch (roleError) {
          // If role fetch fails, default to regular user
          print(
              "⚠️ Could not fetch user role, defaulting to regular user: $roleError");
          if (!mounted) return;
          Get.offAll(() => MainPage());
        }
      }
    } on AuthException catch (e) {
      setState(() {
        switch (e.message) {
          case 'Invalid login credentials':
            errorMessage = "Invalid email or password";
            break;
          case 'Email not confirmed':
            errorMessage = "Please check your email and confirm your account";
            break;
          default:
            errorMessage = "Login failed: ${e.message}";
        }
      });
      print("❌ Auth Error logging in: ${e.message}");
    } catch (e) {
      setState(() {
        errorMessage = "An unexpected error occurred. Please try again.";
      });
      print("❌ Error logging in: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> signUpUser() async {
    // Basic validation
    if (emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      setState(() {
        errorMessage = "Please fill in all fields";
      });
      return;
    }

    if (passwordController.text.length < 6) {
      setState(() {
        errorMessage = "Password must be at least 6 characters long";
      });
      return;
    }

    // Basic email validation
    if (!GetUtils.isEmail(emailController.text.trim())) {
      setState(() {
        errorMessage = "Please enter a valid email address";
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (response.user != null) {
        if (!mounted) return;

        // Check if email confirmation is required
        if (response.user!.emailConfirmedAt == null) {
          // Email confirmation required
          setState(() {
            errorMessage =
                "Please check your email and click the confirmation link to complete registration.";
          });
        } else {
          // Email confirmed, proceed to main page
          Get.offAll(() => MainPage());
        }
      }
    } on AuthException catch (e) {
      setState(() {
        switch (e.message) {
          case 'User already registered':
            errorMessage =
                "An account with this email already exists. Please login instead.";
            break;
          case 'Password should be at least 6 characters':
            errorMessage = "Password must be at least 6 characters long";
            break;
          case 'Unable to validate email address: invalid format':
            errorMessage = "Please enter a valid email address";
            break;
          case 'anonymous_provider_disabled':
            errorMessage =
                "Sign up is currently disabled. Please contact support.";
            break;
          default:
            errorMessage = "Sign up failed: ${e.message}";
        }
      });
      print("❌ Auth Error signing up: ${e.message}");
    } catch (e) {
      setState(() {
        errorMessage = "An unexpected error occurred. Please try again.";
      });
      print("❌ Error signing up: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Get.locale?.languageCode == 'ar'
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        resizeToAvoidBottomInset: true, // Handle keyboard appearance
        appBar: AppBar(
          actions: [
            IconButton(
              icon: const Icon(Icons.language),
              onPressed: () {
                final currentLang = Get.locale?.languageCode ?? 'en';
                final newLang = currentLang == 'en' ? 'ar' : 'en';

                Get.updateLocale(Locale(newLang));
                GetStorage().write('lang', newLang);

                // For RTL support
                Get.forceAppUpdate();
              },
            ),
          ],
          title: Text("Login".tr),
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          // Prevent overflow when keyboard appears
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              height: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  kToolbarHeight -
                  32, // Account for app bar and padding
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(labelText: "Email".tr)),
                  const SizedBox(height: 16),
                  TextField(
                      controller: passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => loginUser(),
                      decoration: InputDecoration(labelText: "Password".tr)),
                  const SizedBox(height: 20),
                  if (errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12.0),
                      margin: const EdgeInsets.only(bottom: 16.0),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  isLoading
                      ? const CircularProgressIndicator()
                      : Column(
                          children: [
                            ElevatedButton(
                              onPressed: loginUser,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                              ),
                              child: Text("Login".tr),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: signUpUser,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                              ),
                              child: Text("Sign Up".tr),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
