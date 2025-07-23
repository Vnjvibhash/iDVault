# iDVault - Aadhaar Scanner App Architecture

## Overview
iDVault is a Flutter-based Aadhaar card scanner and management application that allows users to scan/upload Aadhaar cards, extract information, and manage records locally with export capabilities.

## Core Features
1. **Aadhaar Scanning** - Camera capture and file upload (XML/PDF)
2. **Data Extraction** - Extract Aadhaar details from scanned documents/QR codes
3. **Local Storage** - SQLite database for storing extracted data
4. **Records Management** - View, edit, and delete stored records
5. **Export Functionality** - Export records to Excel (.xlsx) format
6. **QR Code Support** - Scan Aadhaar QR codes for instant data extraction

## Technical Architecture

### Data Models
- **AadhaarRecord**: Core data model with fields:
  - id (auto-increment)
  - aadhaarNumber
  - fullName
  - mobileNumber
  - gender
  - fullAddress
  - createdAt
  - updatedAt

### Core Components
1. **Database Layer** - SQLite with sqflite package
2. **File Handling** - Camera, file picker, and document processing
3. **QR Scanner** - QR code scanning and XML parsing
4. **Excel Export** - Excel file generation and sharing
5. **UI Components** - Modern, accessible Material 3 design

### File Structure
- `lib/main.dart` - App entry point
- `lib/theme.dart` - App theming (already exists)
- `lib/models/aadhaar_record.dart` - Data model
- `lib/services/database_service.dart` - SQLite operations
- `lib/services/file_service.dart` - File handling and processing
- `lib/services/excel_service.dart` - Excel export functionality
- `lib/screens/home_screen.dart` - Main dashboard
- `lib/screens/scan_screen.dart` - Scanning interface
- `lib/screens/records_screen.dart` - Records list view
- `lib/screens/record_detail_screen.dart` - Edit/view record details
- `lib/widgets/record_card.dart` - Reusable record display component
- `lib/utils/aadhaar_parser.dart` - XML/QR code parsing logic

### Dependencies Required
- `sqflite` - SQLite database
- `image_picker` - Camera and gallery access
- `file_picker` - File selection
- `qr_code_scanner` - QR code scanning
- `xml` - XML parsing
- `excel` - Excel file creation
- `path_provider` - File system access
- `share_plus` - File sharing
- `permission_handler` - Device permissions

### Implementation Flow
1. **Setup** - Update pubspec.yaml, configure permissions
2. **Database** - Create SQLite schema and service
3. **Models** - Define Aadhaar record structure
4. **Scanning** - Implement camera/file upload with parsing
5. **Storage** - Connect scanning to database operations
6. **UI** - Build modern interface with records management
7. **Export** - Add Excel export functionality
8. **Testing** - Compile and validate all features

### Key Technical Decisions
- Local-only storage (no cloud integration)
- Material 3 design system
- Modern card-based UI with animations
- Comprehensive error handling for invalid files
- Privacy-focused with secure local storage

