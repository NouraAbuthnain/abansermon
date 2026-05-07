import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PhoneValidationStatus {
  final bool isValid;
  final String? errorKey;
  final String? normalizedValue;

  PhoneValidationStatus({
    required this.isValid,
    this.errorKey,
    this.normalizedValue,
  });
}

class AuthValidator {
  /// Validates full name: Must not be empty and should have at least 3 characters
  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'auth.validation.fullNameEmpty';
    }
    if (value.trim().length < 3) {
      return 'auth.validation.fullNameShort';
    }
    return null;
  }

  /// Validates Saudi phone number based on multiple supported formats:
  /// 05XXXXXXXX, 5XXXXXXXX, 9665XXXXXXXX, +9665XXXXXXXX
  static String? validateSaudiPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'auth.validation.phone.empty';
    }

    // Remove everything except digits and +
    String cleanValue = value.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Check for +9665 format
    if (cleanValue.startsWith('+9665')) {
      if (cleanValue.length == 13) return null;
      return 'auth.validation.phone.invalid';
    }
    
    // Check for 9665 format
    if (cleanValue.startsWith('9665')) {
      if (cleanValue.length == 12) return null;
      return 'auth.validation.phone.invalid';
    }
    
    // Check for 05 format
    if (cleanValue.startsWith('05')) {
      if (cleanValue.length == 10) return null;
      return 'auth.validation.phone.invalid';
    }
    
    // Check for 5 format
    if (cleanValue.startsWith('5')) {
      if (cleanValue.length == 9) return null;
      return 'auth.validation.phone.invalid';
    }

    return 'auth.validation.phone.invalid';
  }

  /// Returns detailed status for real-time validation
  static PhoneValidationStatus getPhoneValidationStatus(String? value) {
    if (value == null || value.trim().isEmpty) {
      return PhoneValidationStatus(isValid: false, errorKey: 'auth.validation.phone.empty');
    }

    String? error = validateSaudiPhone(value);
    if (error != null) {
      return PhoneValidationStatus(isValid: false, errorKey: error);
    }

    return PhoneValidationStatus(
      isValid: true,
      errorKey: 'auth.validation.phone.valid',
      normalizedValue: normalizeSaudiPhone(value),
    );
  }

  /// Normalizes a valid Saudi phone number to +9665XXXXXXXX
  static String normalizeSaudiPhone(String value) {
    String clean = value.replaceAll(RegExp(r'[^\d+]'), '');
    
    if (clean.startsWith('+9665')) {
      return clean;
    } else if (clean.startsWith('9665')) {
      return '+$clean';
    } else if (clean.startsWith('05')) {
      return '+966${clean.substring(1)}';
    } else if (clean.startsWith('5')) {
      return '+966$clean';
    }
    
    // Fallback if something is weird, just return original cleaned
    return clean;
  }

  /// Validates document number based on type
  static String? validateDocNumber(String? value, String docTypeKey) {
    if (value == null || value.trim().isEmpty) {
      return 'auth.validation.docNumberEmpty';
    }
    
    final cleanValue = value.trim();
    
    if (docTypeKey == 'auth.docTypes.nationalId') {
      if (!RegExp(r'^1[0-9]{9}$').hasMatch(cleanValue)) {
        return 'auth.validation.nationalIdInvalid';
      }
    } else if (docTypeKey == 'auth.docTypes.iqama') {
      if (!RegExp(r'^2[0-9]{9}$').hasMatch(cleanValue)) {
        return 'auth.validation.iqamaInvalid';
      }
    } else if (docTypeKey == 'auth.docTypes.passport') {
      if (!RegExp(r'^[A-Za-z0-9]{6,15}$').hasMatch(cleanValue)) {
        return 'auth.validation.passportInvalid';
      }
    }
    return null;
  }
}

/// A formatter that cleans phone input by removing spaces and dashes
class SaudiPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Basic cleaning: ignore spaces and dashes
    final String cleanText = newValue.text.replaceAll(RegExp(r'[\s\-]'), '');
    
    // Maintain the cursor position if possible
    int selectionIndex = newValue.selection.baseOffset;
    
    // If the whole text was replaced or modified with spaces/dashes,
    // we need to adjust selection. 
    // For simplicity, we just return the cleaned text.
    return TextEditingValue(
      text: cleanText,
      selection: TextSelection.collapsed(offset: cleanText.length < selectionIndex ? cleanText.length : selectionIndex),
    );
  }
}
