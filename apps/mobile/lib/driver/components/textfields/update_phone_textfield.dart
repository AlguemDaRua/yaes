import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:limousineexecutive/repositories/auth_repository.dart';
import 'package:limousineexecutive/repositories/trip_repository.dart';
import 'package:provider/provider.dart';

class UpdatePhoneNumberTextfield extends StatefulWidget {
  const UpdatePhoneNumberTextfield({super.key});

  @override
  State<UpdatePhoneNumberTextfield> createState() =>
      _UpdatePhoneNumberTextfieldState();
}

class _UpdatePhoneNumberTextfieldState
    extends State<UpdatePhoneNumberTextfield> {
  final TextEditingController controller = TextEditingController();


  StreamSubscription? _profileSub;
  String phone = '';

  @override
  void initState() {
    super.initState();
    _carregarTelefone();
  }

  Future<void> _carregarTelefone() async {
    final authRepo = Provider.of<IAuthRepository>(context, listen: false);
    final tripRepo = Provider.of<ITripRepository>(context, listen: false);
    final user = authRepo.currentUser;
    if (user != null) {
      _profileSub = tripRepo.watchProfile(user.uid).listen((profile) {
        if (profile != null && mounted) {
          setState(() {
            phone = profile['phone'] ?? '';
            controller.text = phone;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: TextStyle(fontSize: 15.sp, color: Colors.black),
      decoration: InputDecoration(
        hintText: 'Digite o teu número',
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
