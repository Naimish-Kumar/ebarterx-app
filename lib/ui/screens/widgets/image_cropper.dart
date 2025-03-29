import 'dart:io';

import 'package:eBarterx/ui/theme/theme.dart';
import 'package:flutter/material.dart';
// import 'package:image_cropper/image_cropper.dart';

import 'package:eBarterx/utils/extensions/extensions.dart';

//This will open image crop SDK
class CropImage {
  static BuildContext? _context;

  static void init(BuildContext context) {
    _context = context;
  }

  static Future<File?>? crop({required String filePath}) async {
    if (_context == null) {
      return null;
    }

    // File? croppedFile = await ImageCropper().cropImage(
    //   sourcePath: filePath,
    //   androidUiSettings: AndroidUiSettings(
    //     toolbarTitle: 'Cropper',
    //     toolbarColor: _context!.color.territoryColor,
    //     toolbarWidgetColor: Colors.white,
    //     hideBottomControls: false,
    //     activeControlsWidgetColor: _context!.color.territoryColor,
    //     lockAspectRatio: true,
    //     initAspectRatio: CropAspectRatioPreset.square,
    //   ),
    //   iosUiSettings: IOSUiSettings(
    //     title: 'Cropper',
    //   ),
    // );

    return null;
  }
}
