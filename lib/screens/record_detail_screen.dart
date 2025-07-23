import 'package:flutter/material.dart';
import 'package:idvault/models/aadhaar_record.dart';
import 'package:idvault/services/database_service.dart';

class RecordDetailScreen extends StatefulWidget {
  final AadhaarRecord record;
  final bool isNewRecord;

  const RecordDetailScreen({
    super.key,
    required this.record,
    this.isNewRecord = false,
  });

  @override
  State<RecordDetailScreen> createState() => _RecordDetailScreenState();
}

class _RecordDetailScreenState extends State<RecordDetailScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _databaseService = DatabaseService();
  
  late TextEditingController _aadhaarNumberController;
  late TextEditingController _fullNameController;
  late TextEditingController _guardianNameController;
  late TextEditingController _genderController;
  late TextEditingController _fullAddressController;
  
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.isNewRecord;
    _initControllers();
    _setupAnimations();
  }

  void _initControllers() {
    _aadhaarNumberController = TextEditingController(
      text: widget.record.aadhaarNumber,
    );
    _fullNameController = TextEditingController(text: widget.record.fullName);
    _guardianNameController = TextEditingController(
      text: widget.record.guardianName ?? '',
    );
    _genderController = TextEditingController(text: widget.record.gender ?? '');
    _fullAddressController = TextEditingController(
      text: widget.record.fullAddress,
    );
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _aadhaarNumberController.dispose();
    _fullNameController.dispose();
    _guardianNameController.dispose();
    _genderController.dispose();
    _fullAddressController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isNewRecord ? 'New Record' : 'Record Details',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
        elevation: 0,
        actions: [
          if (!widget.isNewRecord && !_isEditing)
            IconButton(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit_rounded),
            ),
          if (_isEditing)
            IconButton(
              onPressed: _isSaving ? null : _saveRecord,
              icon: _isSaving
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    )
                  : const Icon(Icons.save_rounded),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.isNewRecord) _buildPreviewHeader(theme),
                  _buildFormFields(theme),
                  if (widget.isNewRecord) const SizedBox(height: 24),
                  if (widget.isNewRecord) _buildActionButtons(theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewHeader(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(
              Icons.visibility_rounded,
              color: theme.colorScheme.onPrimaryContainer,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preview & Confirm',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    'Review the extracted information and make any necessary changes',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormFields(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        _buildTextField(
          controller: _aadhaarNumberController,
          label: 'Aadhaar Number',
          icon: Icons.credit_card_rounded,
          enabled: _isEditing,
          validator: _validateAadhaarNumber,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _fullNameController,
          label: 'Full Name',
          icon: Icons.person_rounded,
          enabled: _isEditing,
          validator: _validateRequired,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _guardianNameController,
          label: 'Guardian Name',
          icon: Icons.phone_rounded,
          enabled: _isEditing,
          validator: _validateRequired,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _genderController,
          label: 'Gender',
          icon: Icons.family_restroom_rounded,
          enabled: _isEditing,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _fullAddressController,
          label: 'Full Address',
          icon: Icons.location_on_rounded,
          enabled: _isEditing,
          validator: _validateRequired,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
        ),
        if (!_isEditing) ...[
          const SizedBox(height: 24),
          _buildReadOnlyInfo(theme),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    final theme = Theme.of(context);
    
    return TextFormField(
      controller: controller,
      enabled: enabled,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: enabled
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        filled: !enabled,
        fillColor: enabled ? null : theme.colorScheme.surfaceContainer,
      ),
      style: TextStyle(
        color: enabled
            ? theme.colorScheme.onSurface
            : theme.colorScheme.onSurface.withValues(alpha: 0.7),
      ),
    );
  }

  Widget _buildReadOnlyInfo(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Record Information',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Created: ${_formatDateTime(widget.record.createdAt)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                        ),
                      ),
                      if (widget.record.createdAt != widget.record.updatedAt)
                        Text(
                          'Updated: ${_formatDateTime(widget.record.updatedAt)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveRecord,
            icon: _isSaving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.onPrimary,
                    ),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(_isSaving ? 'Saving...' : 'Save Record'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
            label: const Text('Cancel'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  String? _validateAadhaarNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Aadhaar number is required';
    }
    
    return null;
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updatedRecord = widget.record.copyWith(
        aadhaarNumber: _aadhaarNumberController.text.trim(),
        fullName: _fullNameController.text.trim(),
        guardianName: _guardianNameController.text.trim().isNotEmpty
            ? _guardianNameController.text.trim()
            : null,
        gender: _genderController.text.trim().isNotEmpty
            ? _genderController.text.trim()
            : null,
        fullAddress: _fullAddressController.text.trim(),
        updatedAt: DateTime.now(),
      );

      if (widget.isNewRecord) {
        await _databaseService.insertRecord(updatedRecord);
        _showMessage('Record saved successfully!');
      } else {
        await _databaseService.updateRecord(updatedRecord);
        _showMessage('Record updated successfully!');
      }

      Navigator.pop(context, true);
    } catch (e) {
      _showMessage('Failed to save record: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/'
           '${dateTime.month.toString().padLeft(2, '0')}/'
           '${dateTime.year} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}