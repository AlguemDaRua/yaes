import 'package:flutter/material.dart';




class CustomBackButton extends StatelessWidget {
  const CustomBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
    height: 50,
    width: 50,
    decoration: BoxDecoration(
      boxShadow: [
      BoxShadow(
        color: Colors.grey.withValues(alpha: 0.5), 
        spreadRadius: 2, 
        blurRadius: 6, 
        offset: const Offset(0, 4),
      ),
    ],
      shape: BoxShape.circle,
      color: const Color.fromARGB(255, 246, 245, 245)
    ),
    child: Padding(
      padding: const EdgeInsets.only(left: 6),
      child: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios,
          color: Color.fromARGB(255, 137, 137, 137),
        ),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    ),
  );
  }
}