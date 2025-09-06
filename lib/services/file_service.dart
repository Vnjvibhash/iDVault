import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:idvault/models/aadhaar_record.dart';
import 'package:idvault/utils/aadhaar_parser.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PermissionDeniedException implements Exception {
  final String message;
  PermissionDeniedException(this.message);
  @override
  String toString() => message;
}

class FileService {
  static final ImagePicker _imagePicker = ImagePicker();

  /// Request necessary permissions in a modern, platform-aware way.
  static Future<bool> _requestPermissions(List<Permission> permissions) async {
    Map<Permission, PermissionStatus> statuses = await permissions.request();
    return statuses.values.every((status) => status.isGranted);
  }

  /// Pick image from camera.
  static Future<File?> pickImageFromCamera() async {
    try {
      if (!await _requestPermissions([Permission.camera])) {
        throw PermissionDeniedException('Camera permission not granted');
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        preferredCameraDevice: CameraDevice.rear,
      );

      return image != null ? File(image.path) : null;
    } catch (e) {
      if (kDebugMode) print('Failed to capture image: $e');
      rethrow;
    }
  }

  /// Pick image from gallery, handling modern Android permissions.
  static Future<File?> pickImageFromGallery() async {
    try {
      List<Permission> permissionsToRequest;
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt >= 33) {
          permissionsToRequest = [Permission.photos];
        } else {
          permissionsToRequest = [Permission.storage];
        }
      } else {
        permissionsToRequest = [Permission.photos];
      }

      if (!await _requestPermissions(permissionsToRequest)) {
        throw PermissionDeniedException('Photo library permission not granted');
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      return image != null ? File(image.path) : null;
    } catch (e) {
      if (kDebugMode) print('Failed to pick image: $e');
      rethrow;
    }
  }

  /// Pick file (PDF or XML).
  static Future<File?> pickFile() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'xml'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('Failed to pick file: $e');
      throw Exception('Failed to pick file: $e');
    }
  }

  /// Process XML file and extract Aadhaar data.
  static Future<AadhaarRecord?> processXmlFile(File file) async {
    try {
      if (!file.existsSync()) {
        throw Exception('File does not exist');
      }

      final fileSizeBytes = await file.length();
      if (fileSizeBytes > 5 * 1024 * 1024) {
        throw Exception('File size exceeds the 5MB limit');
      }

      final content = await file.readAsString();

      // Let the parser handle validation. No need for redundant checks here.
      final record = AadhaarParser.parseFromXml(content);
      if (record == null) {
        throw Exception(
          'Could not parse valid Aadhaar data from the XML file.',
        );
      }
      return record;
    } catch (e) {
      if (kDebugMode) print('Failed to process XML file: $e');
      rethrow;
    }
  }

  /// Process PDF file (placeholder).
  static Future<AadhaarRecord?> processPdfFile(File file) async {
    throw Exception('PDF processing is not yet implemented.');
  }

  /// Extract text from image (OCR - placeholder).
  static Future<String?> extractTextFromImage(File imageFile) async {
    throw Exception('Image text extraction (OCR) is not yet implemented.');
  }
}
