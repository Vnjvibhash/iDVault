import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:idvault/models/aadhaar_record.dart';

class AadhaarParser {
  static AadhaarRecord? parseFromQrCode(String qrData) {
    final trimmedData = qrData.trim();
    try {
      if (BigInt.tryParse(trimmedData) != null) {
        return _parseSecureQrData(trimmedData);
      }

      if (trimmedData.startsWith('<?xml') ||
          trimmedData.startsWith('<PrintLetterBarcodeData')) {
        return parseFromXml(trimmedData);
      }

      try {
        final decodedData = utf8.decode(base64.decode(trimmedData));
        if (decodedData.startsWith('<?xml')) {
          return parseFromXml(decodedData);
        }
      } catch (_) {}

      return _parsePipeSeparatedQr(trimmedData);
    } catch (e) {
      print("Error in parseFromQrCode: $e");
      return null;
    }
  }

  static AadhaarRecord? _parseSecureQrData(String data) {
    try {
      final bigIntData = BigInt.parse(data);
      final byteData = _bigIntToBytes(bigIntData);
      final decompressedData = ZLibDecoder().decodeBytes(byteData);

      int firstDelimiterIndex = decompressedData.indexOf(255);
      if (firstDelimiterIndex == -1) return null;

      final relevantData = decompressedData.sublist(firstDelimiterIndex + 1);
      final List<String> decodedParts = [];
      List<int> currentPart = [];

      for (final byte in relevantData) {
        if (byte == 255) {
          decodedParts.add(utf8.decode(currentPart, allowMalformed: true));
          currentPart = [];
        } else {
          currentPart.add(byte);
        }
      }

      if (currentPart.isNotEmpty) {
        decodedParts.add(utf8.decode(currentPart, allowMalformed: true));
      }
      
      final last4Digits = decodedParts[1].length >= 4 ? decodedParts[1].substring(0, 4) : '0000';
      final aadhaarNumber = '00000000$last4Digits';

      final fullName = decodedParts[2];
      final guardianName = decodedParts[5];
      final dob = decodedParts[3];
      final gender = decodedParts[4];
      final address = _buildAddress(
        decodedParts[8],
        decodedParts[13],
        decodedParts[7],
        decodedParts[9],
        decodedParts[15],
        decodedParts[6],
        decodedParts[12],
        decodedParts[10],
      );

      return AadhaarRecord(
        aadhaarNumber: aadhaarNumber,
        fullName: fullName,
        guardianName: guardianName,
        dob: dob,
        gender: gender,
        fullAddress: address,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      print("Failed to parse secure QR: $e");
      return null;
    }
  }

  static Uint8List _bigIntToBytes(BigInt number) {
    var hex = number.toRadixString(16);
    if (hex.length % 2 != 0) hex = '0$hex';
    final bytes = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return Uint8List.fromList(bytes);
  }

  static AadhaarRecord? parseFromXml(String xmlData) {
    // TODO: Implement if XML QR parsing is needed
    return null;
  }

  static AadhaarRecord? _parsePipeSeparatedQr(String qrData) {
    // TODO: Implement if pipe-separated QR format is used
    return null;
  }

  static String _buildAddress(
    String house,
    String street,
    String landmark,
    String locality,
    String vtc,
    String district,
    String state,
    String pincode,
  ) {
    final parts = [
      house,
      street,
      landmark,
      locality,
      vtc,
      district,
      state,
      pincode,
    ];
    return parts.where((e) => e.trim().isNotEmpty).join(', ');
  }
}
