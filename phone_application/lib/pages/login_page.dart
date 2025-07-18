import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:phone_application/components/button.dart';
import 'package:phone_application/components/textfield.dart';
import 'package:phone_application/pages/home_page.dart';
import 'package:phone_application/pages/register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final userNameController = TextEditingController();
  final passwordController = TextEditingController();

  String get formattedEmail => '${userNameController.text.trim()}@gmail.com';

  Future<void> _signUserIn(BuildContext context) async {
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: formattedEmail,
        password: passwordController.text.trim(),
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login successful!'), backgroundColor: Colors.green),
      );

      await Future.delayed(const Duration(milliseconds: 100));
      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      String message = switch (e.code) {
        'user-not-found' => 'No user found with that username.',
        'wrong-password' => 'Incorrect password.',
        _ => 'Login failed: ${e.message}',
      };

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider
          ..setCustomParameters({'prompt': 'consent'})
          ..addScope('email');

        await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        await googleSignIn.signOut();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

        if (googleUser == null) return;

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await FirebaseAuth.instance.signInWithCredential(credential);
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed in with Google'), backgroundColor: Colors.green),
      );

      await Future.delayed(const Duration(milliseconds: 100));
      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google sign-in failed'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            double width = constraints.maxWidth > 600 ? 400 : constraints.maxWidth * 0.9;
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Container(
                    width: width,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SelectableText(
                          'Login to meet your SuJok Assistant',
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),

                        MyTextField(
                          controller: userNameController,
                          hintText: 'Username',
                          obscureText: false,
                          isMultiline: false,
                          onSubmit: () => _signUserIn(context),
                        ),
                        const SizedBox(height: 10),

                        MyTextField(
                          controller: passwordController,
                          hintText: 'Password',
                          obscureText: true,
                          isMultiline: false,
                          onSubmit: () => _signUserIn(context),
                        ),
                        const SizedBox(height: 20),

                        MyButton(
                          text: 'Login',
                          onTap: () => _signUserIn(context),
                        ),
                        const SizedBox(height: 20),

                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 25),
                          child: ElevatedButton.icon(
                            onPressed: () => _signInWithGoogle(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black87,
                              minimumSize: const Size(double.infinity, 60),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)
                              ),
                            ),
                            icon: Image.asset(
                              'assets/google_logo.png',
                              height: 24,
                            ),
                            label: const Text(
                              'Sign in with Google',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SelectableText('Not registered yet?'),
                            const SizedBox(width: 5),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const RegisterPage()),
                                );
                              },
                              child: const Text(
                                'Register now',
                                style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
