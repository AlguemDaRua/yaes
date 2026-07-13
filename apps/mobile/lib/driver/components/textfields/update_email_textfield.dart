import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:limousineexecutive/repositories/auth_repository.dart';
import 'package:limousineexecutive/repositories/trip_repository.dart';
import 'package:provider/provider.dart';

class UpdateEmailTextfield extends StatefulWidget {
  const UpdateEmailTextfield({super.key});

  @override
  State<UpdateEmailTextfield> createState() => _UpdateEmailTextfieldState();
}

class _UpdateEmailTextfieldState extends State<UpdateEmailTextfield> {
  final TextEditingController controller = TextEditingController();


  StreamSubscription? _profileSub;
  String email = '';

  @override
  void initState() {
    super.initState();
    _carregarEmail();
  }

  Future<void> _carregarEmail() async {
    final authRepo = Provider.of<IAuthRepository>(context, listen: false);
    final tripRepo = Provider.of<ITripRepository>(context, listen: false);
    final user = authRepo.currentUser;
    if (user != null) {
      _profileSub = tripRepo.watchProfile(user.uid).listen((profile) {
        if (profile != null && mounted) {
          setState(() {
            email = profile['email'] ?? '';
            controller.text = email;
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
        hintText: 'Digite o teu email',
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
