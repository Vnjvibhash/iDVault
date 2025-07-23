import 'dart:typed_data';
import 'dart:convert';
import 'package:archive/archive.dart';

class AadhaarRecord {
  final String? uid;
  final String? name;
  final String? gender;
  final String? dob;
  final String? co;
  final String? address;
  final String? pincode;
  final Uint8List? image;

  AadhaarRecord({
    this.uid,
    this.name,
    this.gender,
    this.dob,
    this.co,
    this.address,
    this.pincode,
    this.image,
  });
}

class SecureQrParser {
  static AadhaarRecord? parse(String scannedData) {
    try {
      final BigInt bigInt = BigInt.parse(scannedData);
      final byteData = _bigIntToBytes(bigInt);
      final decompressedData = Inflate(byteData).getBytes();

      print("✅ Decompressed ${decompressedData.length} bytes.");

      if (decompressedData.isEmpty) {
        print("❌ Decompression failed. Likely not a zlib QR format.");
        return null;
      }

      // Log first 100 bytes for debug
      print(
        "🧪 Decompressed Bytes Sample: ${decompressedData.take(100).toList()}",
      );

      final List<int> delimiterIndexes = [];
      for (int i = 0; i < decompressedData.length; i++) {
        if (decompressedData[i] == 255) {
          delimiterIndexes.add(i);
        }
      }

      if (delimiterIndexes.isEmpty) {
        print("❌ Delimiter 255 not found. Invalid data.");
        return null;
      }

      final List<String> decodedParts = [];
      int startIndex = 0;

      for (int index in delimiterIndexes) {
        decodedParts.add(
          utf8.decode(decompressedData.sublist(startIndex, index)),
        );
        startIndex = index + 1;
      }

      // Log all fields
      for (int i = 0; i < decodedParts.length; i++) {
        print("📌 Field $i: ${decodedParts[i]}");
      }

      if (decodedParts.length < 10) {
        print("❌ Insufficient fields. Got ${decodedParts.length} parts.");
        return null;
      }

      final imageBytes = decompressedData.sublist(
        startIndex,
      ); // Remaining is image
      return AadhaarRecord(
        uid: decodedParts[0],
        name: decodedParts[1],
        gender: decodedParts[2],
        dob: decodedParts[3],
        co: decodedParts[4],
        address: decodedParts[5],
        pincode: decodedParts[6],
        image: Uint8List.fromList(imageBytes),
      );
    } catch (e) {
      print("❌ Error parsing secure QR data: $e");
      return null;
    }
  }

  static List<int> _bigIntToBytes(BigInt bigInt) {
    final bytes = <int>[];
    BigInt temp = bigInt;
    while (temp > BigInt.zero) {
      bytes.insert(0, (temp & BigInt.from(0xff)).toInt());
      temp = temp >> 8;
    }
    return bytes;
  }
}
