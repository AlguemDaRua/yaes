import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:limousineexecutive/driver/components/textfields/neighborhood_textfield.dart';
import 'package:limousineexecutive/driver/components/textfields/date_textfield.dart';
import 'package:limousineexecutive/driver/components/textfields/dropdown_gender.dart';
import 'package:limousineexecutive/driver/components/textfields/update_email_textfield.dart';
import 'package:limousineexecutive/driver/components/textfields/update_name_textfield.dart';
import 'package:limousineexecutive/driver/components/textfields/update_phone_textfield.dart';
import 'package:limousineexecutive/repositories/auth_repository.dart';
import 'package:limousineexecutive/repositories/trip_repository.dart';
import 'package:limousineexecutive/services/storage_service.dart';
import 'package:provider/provider.dart';

class DriverProfile extends StatefulWidget {
  const DriverProfile({super.key});

  @override
  State<DriverProfile> createState() => _DriverProfileState();
}

class _DriverProfileState extends State<DriverProfile> {
  File? _image;
  Color mainColor = Colors.amber.withValues(alpha: 0.59);

  final StorageService _storageService = StorageService();
  bool _uploadingPhoto = false;

  StreamSubscription? _profileSub;
  String name = '';
  String phone = '';
  String email = '';
  String photoUrl = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final authRepo = Provider.of<IAuthRepository>(context, listen: false);
    final tripRepo = Provider.of<ITripRepository>(context, listen: false);
    final user = authRepo.currentUser;
    if (user != null) {
      _profileSub = tripRepo.watchProfile(user.uid).listen((profile) {
        if (profile != null && mounted) {
          setState(() {
            name = profile['name'] ?? '';
            phone = profile['phone'] ?? '';
            email = profile['email'] ?? '';
            photoUrl = profile['photoUrl'] ?? '';
          });
        }
      });
    }
  }

  Future<void> _saveChanges() async {
    final authRepo = Provider.of<IAuthRepository>(context, listen: false);
    final tripRepo = Provider.of<ITripRepository>(context, listen: false);
    final user = authRepo.currentUser;
    if (user != null) {
      await tripRepo.updateProfile(user.uid, {
        'name': name,
        'email': email,
        'phone': phone,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Perfil actualizado!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 20.sp),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Hero(
                    tag: "user",
                    child: GestureDetector(
                      onTap: () => _pickFromGallery(),
                      child: Stack(
                        children: [
                          Container(
                            padding: EdgeInsets.all(1.sp),
                            decoration: BoxDecoration(
                              border: Border.all(color: mainColor, width: 3.sp),
                              shape: BoxShape.circle,
                            ),
                            child: _uploadingPhoto
                                ? SizedBox(
                                    width: 80.sp,
                                    height: 80.sp,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: mainColor,
                                      ),
                                    ),
                                  )
                                : ClipOval(
                                    child: _image != null
                                        ? (kIsWeb
                                              ? Image.network(
                                                  _image!.path,
                                                  width: 80.sp,
                                                  height: 80.sp,
                                                  fit: BoxFit.cover,
                                                )
                                              : Image.file(
                                                  _image!,
                                                  width: 80.sp,
                                                  height: 80.sp,
                                                  fit: BoxFit.cover,
                                                ))
                                        : (photoUrl.isNotEmpty
                                              ? Image.network(
                                                  photoUrl,
                                                  width: 80.sp,
                                                  height: 80.sp,
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) => Container(
                                                        width: 80.sp,
                                                        height: 80.sp,
                                                        color: Colors.grey
                                                            .withAlpha(40),
                                                        child: Icon(
                                                          Icons.person,
                                                          color: Colors.grey,
                                                          size: 35.sp,
                                                        ),
                                                      ),
                                                )
                                              : Container(
                                                  width: 80.sp,
                                                  height: 80.sp,
                                                  color: Colors.grey.withAlpha(
                                                    40,
                                                  ),
                                                  child: Icon(
                                                    Icons.person,
                                                    color: Colors.grey,
                                                    size: 35.sp,
                                                  ),
                                                )),
                                  ),
                          ),

                          Positioned(
                            bottom: 10.sp,
                            right: 0,
                            child: Container(
                              padding: EdgeInsets.all(1.sp),
                              decoration: BoxDecoration(
                                color: mainColor,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Icon(Icons.camera_alt, size: 15.sp),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.sp),

              // Nome Completo
              Text('Nome Completo', style: TextStyle(fontSize: 18.sp)),
              SizedBox(height: 8.sp),
              const UpdateNameTextfield(),

              SizedBox(height: 18.sp),

              // Numero de phone
              Text('Número de Telefone', style: TextStyle(fontSize: 18.sp)),
              SizedBox(height: 8.sp),
              const UpdatePhoneNumberTextfield(),

              SizedBox(height: 18.sp),

              // Email
              Text('Email', style: TextStyle(fontSize: 18.sp)),
              SizedBox(height: 8.sp),
              const UpdateEmailTextfield(),

              SizedBox(height: 18.sp),

              // Data
              Text('Data de Nascimento', style: TextStyle(fontSize: 18.sp)),
              SizedBox(height: 8.sp),
              const DateInputField(),

              SizedBox(height: 18.sp),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Género', style: TextStyle(fontSize: 18.sp)),
                        SizedBox(height: 8.sp),
                        const SelectGender(),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bairro', style: TextStyle(fontSize: 18.sp)),
                        SizedBox(height: 8.sp),
                        const UpdateNeighborhoodTextfield(),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 40.sp),

              Center(
                child: GestureDetector(
                  onTap: () => _saveChanges(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: mainColor,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    alignment: Alignment.center,
                    height: 50.sp,
                    width: double.infinity,
                    child: Text(
                      'Submeter Alterações',
                      style: TextStyle(fontSize: 15.sp, color: Colors.black),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 20.sp),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedImage = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedImage == null) return;
    if (!mounted) return;

    final authRepo = Provider.of<IAuthRepository>(context, listen: false);
    final tripRepo = Provider.of<ITripRepository>(context, listen: false);
    final user = authRepo.currentUser;
    if (user == null) {
      setState(() => _uploadingPhoto = false);
      return;
    }

    setState(() {
      _uploadingPhoto = true;
      if (!kIsWeb) {
        _image = File(pickedImage.path);
      }
    });

    try {
      // 1. Upload to Firebase Storage
      final url = await _storageService.uploadProfilePhoto(
        user.uid,
        pickedImage,
      );

      if (url != null) {
        // 2. Save the URL in the Realtime Database
        await tripRepo.updateProfile(user.uid, {'photoUrl': url});
        if (mounted) {
          setState(() => photoUrl = url);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto de perfil actualizada!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao fazer upload da foto.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }
}
