import 'package:flutter/material.dart';

class PasswordField extends StatefulWidget {
  const PasswordField({super.key});

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;
  String? _errorText;

  void _validatePassword(String value) {
    if (value.length < 5) {
      setState(() => _errorText = "Mínimo de 5 caracteres");
    } else if (!value.contains(RegExp(r'[A-Z]'))) {
      setState(() => _errorText = "Deve ter pelo menos 1 letra maiúscula");
    } else if (!value.contains(RegExp(r'[!@#$%^&*(),.?\":{}|<>]'))) {
      setState(() => _errorText = "Deve ter pelo menos 1 caractere especial");
    } else {
      setState(() => _errorText = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        obscureText: _obscureText,
        onChanged: _validatePassword,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          prefixIcon: const Icon(Icons.lock),
          hintText: "Password",  // <-- hintText here, not labelText
          errorText: _errorText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureText ? Icons.visibility_off : Icons.visibility,
            ),
            onPressed: () {
              setState(() {
                _obscureText = !_obscureText;
              });
            },
          ),
        ),
      ),
    );
  }
}
