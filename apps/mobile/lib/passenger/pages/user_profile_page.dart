import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:limousineexecutive/repositories/auth_repository.dart';
import 'package:limousineexecutive/repositories/trip_repository.dart';
import 'package:limousineexecutive/services/storage_service.dart';
import 'package:provider/provider.dart';
import '../../utils/asset_paths.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  File? _image;
  String name = '';
  String number = '';
  String email = '';
  String? rating; // null = no trips yet
  String photoUrl = '';
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();

  final StorageService _storageService = StorageService();

  StreamSubscription? _profileSub;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    nameController.dispose();
    emailController.dispose();
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
            number = profile['phone'] ?? '';
            email = profile['email'] ?? '';
            rating = profile['rating']?.toString(); // null if no trips
            photoUrl = profile['photoUrl'] ?? '';
            nameController.text = name;
          });
        }
      });
    }
  }

  Divider dividerModal = Divider(
    color: Colors.black.withAlpha(88),
    thickness: 3.0,
    height: 18,
    indent: 180,
    endIndent: 180,
  );

  Future<void> _pickFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedImage = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedImage != null && mounted) {
      final authRepo = Provider.of<IAuthRepository>(context, listen: false);
      final tripRepo = Provider.of<ITripRepository>(context, listen: false);
      final user = authRepo.currentUser;
      if (user != null) {
        // Upload the image
        final downloadUrl = await _storageService.uploadProfilePhoto(
          user.uid,
          pickedImage,
        );

        if (downloadUrl != null) {
          // Update profile with photo URL
          await tripRepo.updateProfile(user.uid, {'photoUrl': downloadUrl});

          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Foto actualizada!')));
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao actualizar foto')),
          );
        }
      }

      setState(() {
        _image = File(pickedImage.path);
      });
    }
  }

  // ── Shared bottom-sheet builder ──────────────────────────────────────────
  /// Builds a themed input bottom-sheet.
  /// [title] is the label shown above the field.
  /// [controller] is the text controller.
  /// [hint] is the placeholder text.
  /// [keyboardType] adjusts the soft keyboard.
  /// [validator] validates before saving.
  /// [onSave] is called with the trimmed value when the form is valid.
  Future<void> _showInputSheet({
    required String title,
    required String subtitle,
    required TextEditingController controller,
    required String hint,
    required TextInputType keyboardType,
    required String? Function(String?) validator,
    required Future<void> Function(String value) onSave,
  }) {
    final formKey = GlobalKey<FormState>();

    return showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: MediaQuery.of(ctx).viewInsets,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.sp, 12.sp, 20.sp, 28.sp),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: EdgeInsets.only(bottom: 18.sp),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(50),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  // Title
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 4.sp),
                  // Subtitle
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 18.sp),
                  // Input field
                  TextFormField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: keyboardType,
                    textCapitalization: keyboardType == TextInputType.name
                        ? TextCapitalization.words
                        : TextCapitalization.none,
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                    validator: validator,
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: GoogleFonts.poppins(
                        color: Colors.grey,
                        fontSize: 14.sp,
                      ),
                      filled: true,
                      fillColor: Colors.grey.withAlpha(18),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 14.sp,
                        horizontal: 22.sp,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(600),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(600),
                        borderSide: BorderSide(
                          color: Colors.grey.withAlpha(60),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(600),
                        borderSide: const BorderSide(
                          color: Color(0xffe5a400),
                          width: 1.5,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(600),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 1,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(600),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.sp),
                  // Save button
                  GestureDetector(
                    onTap: () async {
                      if (formKey.currentState!.validate()) {
                        await onSave(controller.text.trim());
                        if (ctx.mounted) Navigator.of(ctx).pop();
                      }
                    },
                    child: Container(
                      height: 54.sp,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xffe5a400),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xffe5a400).withAlpha(80),
                            spreadRadius: 0,
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Guardar',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _modalBottomName() => _showInputSheet(
    title: 'O teu nome',
    subtitle: 'Como queres ser chamado?',
    controller: nameController,
    hint: 'Ex: João Silva',
    keyboardType: TextInputType.name,
    validator: (value) {
      final nameRegex = RegExp(r'^[A-Za-zÀ-ú\s]+$');
      if (value == null || value.trim().isEmpty) return 'Digite o teu nome';
      if (!nameRegex.hasMatch(value)) return 'Use apenas letras';
      if (value.trim().length < 2) return 'Mínimo de 2 letras';
      return null;
    },
    onSave: (value) async {
      setState(() => name = value);
      final authRepo = Provider.of<IAuthRepository>(context, listen: false);
      final tripRepo = Provider.of<ITripRepository>(context, listen: false);
      final user = authRepo.currentUser;
      if (user != null) {
        await tripRepo.updateProfile(user.uid, {'name': value});
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Nome actualizado!')));
        }
      }
    },
  );

  Future<void> _modalBottomEmail() => _showInputSheet(
    title: 'O teu email',
    subtitle: 'Adiciona um email à tua conta',
    controller: emailController,
    hint: 'Ex: joao@email.com',
    keyboardType: TextInputType.emailAddress,
    validator: (value) {
      if (value == null || value.trim().isEmpty) return 'Digite o teu email';
      final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.]+$');
      if (!emailRegex.hasMatch(value.trim())) return 'Email inválido';
      return null;
    },
    onSave: (value) async {
      setState(() => email = value);
      final authRepo = Provider.of<IAuthRepository>(context, listen: false);
      final tripRepo = Provider.of<ITripRepository>(context, listen: false);
      final user = authRepo.currentUser;
      if (user != null) {
        await tripRepo.updateProfile(user.uid, {'email': value});
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Email actualizado!')));
        }
      }
    },
  );

  @override
  Widget build(BuildContext context) {
    TextStyle title = TextStyle(
      fontSize: 13.sp,
      fontWeight: FontWeight.normal,
      color: Colors.grey,
    );

    final TextStyle subtitle = TextStyle(
      fontSize: 15.sp,
      fontWeight: FontWeight.w400,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),

      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 20.sp),
                child: Padding(
                  padding: EdgeInsets.only(left: 19.sp),
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 25.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.4.sp,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  _pickFromGallery();
                },
                child: Hero(
                  tag: "user",
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.sp),
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                        child: _image == null
                            ? (photoUrl.isNotEmpty
                                  ? ClipOval(
                                      child: Image.network(
                                        photoUrl,
                                        width: 50.sp,
                                        height: 50.sp,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) => Container(
                                              width: 50.sp,
                                              height: 50.sp,
                                              color: Colors.grey.withAlpha(40),
                                              child: Icon(Icons.person, color: Colors.grey, size: 24.sp),
                                            ),
                                      ),
                                    )
                                  : Container(
                                      width: 50.sp,
                                      height: 50.sp,
                                      color: Colors.grey.withAlpha(40),
                                      child: Icon(Icons.person, color: Colors.grey, size: 24.sp),
                                    ))
                            : ClipOval(
                                child: kIsWeb
                                    ? Image.network(
                                        _image!.path,
                                        width: 50.sp,
                                        height: 50.sp,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        _image!,
                                        width: 50.sp,
                                        height: 50.sp,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                      ),
                      Positioned(
                        bottom: 8.sp,
                        right: 8.sp,
                        child: Container(
                          padding: EdgeInsets.all(4.sp),
                          decoration: BoxDecoration(
                            color: const Color(0xffe5a400),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            size: 14.sp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.sp),
          ListTile(
            title: Text('Telefone', style: title),
            subtitle: Text(
              number.isNotEmpty ? number : 'Não disponível',
              style: subtitle,
            ),
          ),
          ListTile(
            title: Text('Nome', style: title),
            subtitle: Text(name, style: subtitle),
            onTap: () {
              _modalBottomName();
              // showPaymentMethodModal(context);
            },
          ),
          ListTile(
            title: Text('Avaliação do utilizador', style: title),
            trailing: Image.asset(
              AssetPaths.info,
              width: 18.sp,
              color: Colors.grey,
            ),
            subtitle: Text(rating ?? 'Novo utilizador', style: subtitle),
          ),
          ListTile(
            minTileHeight: 60.sp,
            title: Text(
              email.isNotEmpty ? email : 'Adicionar email',
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.normal,
                color: Colors.white,
              ),
            ),
            subtitle: email.isNotEmpty
                ? Text(
                    'Toca para alterar',
                    style: TextStyle(fontSize: 11.sp, color: Colors.white70),
                  )
                : null,
            tileColor: const Color(0xffe5a400),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 14.sp,
              color: Colors.white,
            ),
            onTap: () => _modalBottomEmail(),
          ),
        ],
      ),
    );
  }
}
