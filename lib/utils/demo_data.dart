import 'package:idvault/models/aadhaar_record.dart';

class DemoData {
  static List<AadhaarRecord> getSampleRecords() {
    final now = DateTime.now();
    
    return [
      AadhaarRecord(
        aadhaarNumber: '123456789012',
        fullName: 'Rajesh Kumar Singh',
        guardianName: 'Viveka Jee',
        gender: 'M',
        fullAddress: 'House No. 123, Sector 15, Dwarka, New Delhi, Delhi, 110075',
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
      AadhaarRecord(
        aadhaarNumber: '234567890123',
        fullName: 'Priya Sharma',
        guardianName: 'Viveka Jee',
        gender: 'F',
        fullAddress: 'Flat B-205, Green Valley Apartments, Sector 22, Noida, Uttar Pradesh, 201301',
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      AadhaarRecord(
        aadhaarNumber: '345678901234',
        fullName: 'Mohammed Ali Khan',
        guardianName: 'Viveka Jee',
        gender: 'M',
        fullAddress: 'Plot No. 45, Jubilee Hills, Hyderabad, Telangana, 500033',
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      AadhaarRecord(
        aadhaarNumber: '456789012345',
        fullName: 'Sunita Devi',
        guardianName: null,
        gender: 'F',
        fullAddress: 'Village Rampur, Post Rampur, Tehsil Sadar, District Muzaffarpur, Bihar, 842001',
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now.subtract(const Duration(days: 7)),
      ),
      AadhaarRecord(
        aadhaarNumber: '567890123456',
        fullName: 'Arjun Patel',
        guardianName: 'Viveka Jee',
        gender: null,
        fullAddress: '12, Gandhi Street, Sarkhej, Ahmedabad, Gujarat, 382210',
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      ),
    ];
  }

  /// Generate sample Aadhaar XML for testing
  static String getSampleAadhaarXml() {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<PrintLetterBarcodeData 
  uid="987654321012" 
  name="Test User"
  phone="9876543210" 
  gender="M"
  house="House 456" 
  street="Test Street" 
  lm="Near Test Landmark" 
  loc="Test Locality" 
  vtc="Test City" 
  dist="Test District" 
  state="Test State" 
  pc="123456" />''';
  }

  /// Generate sample QR code data
  static String getSampleQrData() {
    return getSampleAadhaarXml();
  }

  /// Generate pipe-separated QR format for testing
  static String getSamplePipeQrData() {
    return 'Test Name|Test Gender|Test Address, Test City, Test State, 123456|987654321012|9876543210';
  }
}