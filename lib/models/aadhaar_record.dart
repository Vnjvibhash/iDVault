class AadhaarRecord {
  final int? id;
  final String aadhaarNumber;
  final String fullName;
  final String? guardianName;
  final String? dob;
  final String? gender;
  final String fullAddress;
  final DateTime createdAt;
  final DateTime updatedAt;

  AadhaarRecord({
    this.id,
    required this.aadhaarNumber,
    required this.fullName,
    this.guardianName,
    this.dob,
    this.gender,
    required this.fullAddress,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'aadhaarNumber': aadhaarNumber,
      'fullName': fullName,
      'guardianName': guardianName,
      'dob': dob,
      'gender': gender,
      'fullAddress': fullAddress,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AadhaarRecord.fromMap(Map<String, dynamic> map) {
    return AadhaarRecord(
      id: map['id']?.toInt(),
      aadhaarNumber: map['aadhaarNumber'] ?? '',
      fullName: map['fullName'] ?? '',
      guardianName: map['guardianName'],
      dob: map['dob'],
      gender: map['gender'],
      fullAddress: map['fullAddress'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  AadhaarRecord copyWith({
    int? id,
    String? aadhaarNumber,
    String? fullName,
    String? guardianName,
    String? dob,
    String? gender,
    String? fullAddress,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AadhaarRecord(
      id: id ?? this.id,
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      fullName: fullName ?? this.fullName,
      guardianName: guardianName ?? this.guardianName,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      fullAddress: fullAddress ?? this.fullAddress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get maskedAadhaarNumber {
    if (aadhaarNumber.length >= 12) {
      return 'XXXX XXXX ${aadhaarNumber.substring(8)}';
    }
    return aadhaarNumber;
  }

  bool get isValid {
    return aadhaarNumber.isNotEmpty &&
        fullName.isNotEmpty &&
        fullAddress.isNotEmpty &&
        aadhaarNumber.replaceAll(RegExp(r'[^0-9]'), '').length == 12;
  }
}
