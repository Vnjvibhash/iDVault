import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:idvault/models/aadhaar_record.dart';
import 'package:idvault/screens/record_detail_screen.dart';
import 'package:idvault/screens/records_screen.dart';
import 'package:idvault/services/database_service.dart';
import 'package:idvault/services/file_service.dart';
import 'package:idvault/utils/aadhaar_parser.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  final MobileScannerController _scannerController = MobileScannerController();

  bool _isScanning = false;
  bool _isProcessing = false;
  String? _scanResult;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Scan Aadhaar',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
        elevation: 0,
      ),
      body: ScaleTransition(
        scale: _scaleAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isScanning) _buildQrScanner(theme),
              if (_isProcessing) _buildProcessingIndicator(theme),
              if (_scanResult != null) _buildScanResult(theme),
              const SizedBox(height: 24),
              _buildScanningOptions(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanningOptions(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Scanning Method',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        _buildScanOption(
          theme: theme,
          icon: Icons.qr_code_scanner_rounded,
          title: 'Scan QR Code',
          subtitle: 'Use camera to scan Aadhaar QR code',
          onTap: _startQrScanning,
        ),
        const SizedBox(height: 12),
        _buildScanOption(
          theme: theme,
          icon: Icons.camera_alt_rounded,
          title: 'Take Photo',
          subtitle: 'Capture Aadhaar card with camera',
          onTap: _captureFromCamera,
        ),
        const SizedBox(height: 12),
        _buildScanOption(
          theme: theme,
          icon: Icons.photo_library_rounded,
          title: 'Choose from Gallery',
          subtitle: 'Select Aadhaar image from gallery',
          onTap: _selectFromGallery,
        ),
        const SizedBox(height: 12),
        _buildScanOption(
          theme: theme,
          icon: Icons.upload_file_rounded,
          title: 'Upload File',
          subtitle: 'Upload XML or PDF file',
          onTap: _uploadFile,
        ),
      ],
    );
  }

  Widget _buildScanOption({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: _isProcessing ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQrScanner(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 300,
          child: Stack(
            alignment: Alignment.center,
            children: [
              MobileScanner(
                controller: _scannerController,
                onDetect: (capture) {
                  if (_isProcessing) return;
                  final List<Barcode> barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty) {
                    final String? code = barcodes.first.rawValue;
                    if (code != null) {
                      _processQrData(code);
                    }
                  }
                },
              ),
              Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.7),
                    width: 4,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingIndicator(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            CircularProgressIndicator(
              color: theme.colorScheme.onPrimaryContainer,
            ),
            const SizedBox(height: 16),
            Text(
              'Processing...',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Extracting Aadhaar information',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanResult(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.secondaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: theme.colorScheme.onSecondaryContainer,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Scan Completed',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _scanResult!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSecondaryContainer.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _resetScanning,
              child: const Text('Scan Another'),
            ),
          ],
        ),
      ),
    );
  }

  void _startQrScanning() {
    setState(() {
      _isScanning = true;
      _scanResult = null;
    });
  }

  Future<void> _captureFromCamera() async {
    try {
      setState(() => _isProcessing = true);
      final imageFile = await FileService.pickImageFromCamera();
      if (imageFile != null) {
        _showMessage(
          'Image OCR processing not yet implemented. Please use QR code scanning.',
        );
      }
    } catch (e) {
      _showMessage('Failed to capture image: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _selectFromGallery() async {
    try {
      setState(() => _isProcessing = true);
      final imageFile = await FileService.pickImageFromGallery();
      if (imageFile != null) {
        _showMessage(
          'Image OCR processing not yet implemented. Please use QR code scanning.',
        );
      }
    } catch (e) {
      _showMessage('Failed to select image: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _uploadFile() async {
    try {
      setState(() => _isProcessing = true);
      final file = await FileService.pickFile();
      if (file != null) {
        final extension = file.path.split('.').last.toLowerCase();

        AadhaarRecord? record;
        if (extension == 'xml') {
          record = await FileService.processXmlFile(file);
        } else if (extension == 'pdf') {
          await FileService.processPdfFile(file);
        } else {
          throw Exception('Unsupported file type: $extension');
        }

        if (record != null) {
          await _saveAndNavigateToRecord(record);
        } else {
          _showMessage('Could not extract Aadhaar data from file');
        }
      }
    } catch (e) {
      _showMessage('Failed to process file: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _processQrData(String qrData) async {
    // --- THIS IS THE ADDED DEBUGGING LINE ---
    log('Scanned QR Data: $qrData');
    if (_isProcessing) return;

    // Stop the camera IMMEDIATELY to prevent the crash. This is the key fix.
    await _scannerController.stop();

    if (!mounted) return;

    setState(() {
      _isProcessing = true;
      _isScanning = false;
    });

    try {
      final record = AadhaarParser.parseFromQrCode(qrData);

      if (!mounted) return;

      if (record != null) {
        await _saveAndNavigateToRecord(record);
      } else {
        setState(() {
          _scanResult = 'Could not extract valid Aadhaar data from QR code.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _scanResult = 'An error occurred while processing the QR code: $e';
      });
    } finally {
      if (mounted) {
        // Only set processing to false if we are not navigating away (i.e., an error occurred)
        if (_scanResult != null) {
          setState(() => _isProcessing = false);
        }
      }
    }
  }

  Future<void> _saveAndNavigateToRecord(AadhaarRecord record) async {
    try {
      final exists = await DatabaseService().recordExists(record.aadhaarNumber);
      if (exists) {
        _showMessage('This Aadhaar record already exists in your database');
        setState(() {
          _isProcessing = false;
          _scanResult = null;
        });
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const RecordsScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  );
                },
          ),
        );
        return;
      }

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              RecordDetailScreen(record: record, isNewRecord: true),
        ),
      );

      if (result == true) {
        setState(() {
          _scanResult = 'Aadhaar record saved successfully!';
        });
      }
    } catch (e) {
      _showMessage('Failed to process record: $e');
    }
  }

  void _resetScanning() {
    setState(() {
      _isScanning = true;
      _isProcessing = false;
      _scanResult = null;
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
