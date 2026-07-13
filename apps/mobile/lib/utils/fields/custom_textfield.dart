import 'package:flutter/material.dart';


class CustomTextfield extends StatelessWidget {
  final String label;  
  final IconData icon;
  const CustomTextfield({super.key, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
    height: 60,
    decoration: BoxDecoration(
      color: Colors.white, // field background
      
      borderRadius: BorderRadius.circular(30), // rounded corners
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          spreadRadius: 2,
          blurRadius: 8,
          offset: const Offset(0, 3), // shadow offset
        ),
      ],
    ),
    child: Center(
      child: TextField(
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          prefixIcon: Icon(icon),
          hintText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none, // remove default border
          ),
        ),
      ),
    ),
  );
  }
}