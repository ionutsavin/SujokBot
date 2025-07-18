import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class MyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final VoidCallback? onSubmit;
  final bool isMultiline;

  const MyTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
    required this.isMultiline,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        maxLines: isMultiline ? null : 1,
        keyboardType: obscureText ? TextInputType.text : TextInputType.multiline,
        textInputAction: TextInputAction.done,
        onSubmitted: kIsWeb ? (_) => onSubmit?.call() : null,
        decoration: InputDecoration(
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
          fillColor: Colors.white,
          filled: true,
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}