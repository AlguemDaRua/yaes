import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:limousineexecutive/utils/asset_paths.dart';

Widget downloadPdfButton({
  required BuildContext context,
  required VoidCallback setState,
}) {
  return InkWell(
    onTap: () {
      setState();
      Fluttertoast.showToast(
        msg: 'Factura baixada com sucesso!',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM, // aparece no topo
        backgroundColor: Colors.white.withValues(alpha: 0.59),
        textColor: Colors.black,
        fontSize: 14.0.sp,
      );
    },
    child: Container(
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.59),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Container(
            height: 50.sp,
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Image.asset(AssetPaths.downloadpdf, scale: 20),
          ),

          SizedBox(width: 20.sp),
          Text(
            'BAIXA A FACTURA!',
            style: TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 26.sp,
              fontFamily: 'Gagalin',
              letterSpacing: 0.8.sp,
            ),
          ),
        ],
      ),
    ),
  );
}
