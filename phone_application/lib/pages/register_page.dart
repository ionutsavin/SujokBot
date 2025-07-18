import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:phone_application/components/button.dart';
import 'package:phone_application/components/textfield.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final userNameController = TextEditingController();
  final passwordController = TextEditingController();
  final repeatPasswordController = TextEditingController();

  String _getEmail(String username) => '$username@gmail.com';

  Future<void> _registerUser(BuildContext context) async {
    final username = userNameController.text.trim();
    final password = passwordController.text.trim();
    final repeatPassword = repeatPasswordController.text.trim();

    if (password != repeatPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _getEmail(username),
        password: password,
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String errorMessage = switch (e.code) {
        'email-already-in-use' => 'Username is already taken.',
        'weak-password' => 'Password is too weak.',
        _ => 'Registration failed: ${e.message}',
      };

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: LayoutBuilder(
              builder: (context, constraints) {
                double width = constraints.maxWidth > 600 ? 400 : constraints.maxWidth * 0.9;
                return Card(
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
                          'Register',
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        MyTextField(
                          controller: userNameController,
                          hintText: 'Username',
                          obscureText: false,
                          isMultiline: false,
                          onSubmit: () => _registerUser(context),
                        ),
                        const SizedBox(height: 10),
                        MyTextField(
                          controller: passwordController,
                          hintText: 'Password',
                          obscureText: true,
                          isMultiline: false,
                          onSubmit: () => _registerUser(context),
                        ),
                        const SizedBox(height: 10),
                        MyTextField(
                          controller: repeatPasswordController,
                          hintText: 'Repeat Password',
                          obscureText: true,
                          isMultiline: false,
                          onSubmit: () => _registerUser(context),
                        ),
                        const SizedBox(height: 10),
                        MyButton(
                          text: 'Register',
                          onTap: () => _registerUser(context),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SelectableText('Already registered?'),
                            const SizedBox(width: 5),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Text(
                                'Back to login',
                                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
