import 'dart:io';
import 'package:flutter/material.dart';

Widget buildPlatformFileImage(
  String path, {
  double? height,
  double? width,
  BoxFit? fit,
  Color? color,
  String placeHolder = 'assets/images/image_not_found.png',
}) {
  return Image.file(
    File(path),
    height: height,
    width: width,
    fit: fit ?? BoxFit.cover,
    color: color,
    errorBuilder: (context, error, stackTrace) => Image.asset(
      placeHolder,
      height: height,
      width: width,
      fit: fit ?? BoxFit.cover,
    ),
  );
}
