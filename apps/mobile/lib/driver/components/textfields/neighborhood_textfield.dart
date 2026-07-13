import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UpdateNeighborhoodTextfield extends StatefulWidget {
  const UpdateNeighborhoodTextfield({super.key});

  @override
  State<UpdateNeighborhoodTextfield> createState() => _UpdateNeighborhoodTextfieldState();
}

class _UpdateNeighborhoodTextfieldState extends State<UpdateNeighborhoodTextfield> {
  final TextEditingController controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: TextStyle(fontSize: 15.sp, color: Colors.black),
      decoration: InputDecoration(
        hintText: 'Teu bairro',
        hintStyle: TextStyle(fontSize: 15.sp, color: Colors.grey),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12.sp,
          vertical: 10.sp,
        ),
      ),
    );
  }
}
