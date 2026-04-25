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

  /// Validates Saudi phone number based on strict rules
  static String? validateSaudiPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'auth.validation.phone.empty';
    }

    String cleanValue = value.replaceAll(RegExp(r'[^\d+]'), '');
    String digitsOnly = cleanValue.replaceAll('+', '');

    if (digitsOnly.startsWith('05')) {
      if (digitsOnly.length != 10) return 'auth.validation.phone.invalid';
    } else if (digitsOnly.startsWith('5')) {
      if (digitsOnly.length != 9) return 'auth.validation.phone.invalid';
    } else if (digitsOnly.startsWith('9665')) {
      if (digitsOnly.length != 12) return 'auth.validation.phone.invalid';
    } else {
      return 'auth.validation.phone.invalid';
    }

    return null;
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
    String digits = value.replaceAll(RegExp(r'\D'), '');
    
    if (digits.startsWith('966')) {
      return '+$digits';
    } else if (digits.startsWith('05')) {
      return '+966${digits.substring(1)}';
    } else if (digits.startsWith('5')) {
      return '+966$digits';
    }
    
    return value;
  }

  /// Validates password: at least 8 characters
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'auth.validation.password.empty';
    }
    if (value.length < 8) {
      return 'auth.validation.password.tooShort';
    }
    return null;
  }

  /// Returns detailed status for password validation
  static ({bool isValid, String? errorKey, bool isWeak}) getPasswordValidationStatus(String? value) {
    if (value == null || value.isEmpty) {
      return (isValid: false, errorKey: 'auth.validation.password.empty', isWeak: false);
    }
    if (value.length < 8) {
      return (isValid: false, errorKey: 'auth.validation.password.tooShort', isWeak: false);
    }
    
    final hasLetters = value.contains(RegExp(r'[a-zA-Z]'));
    final hasDigits = value.contains(RegExp(r'[0-9]'));
    
    if (!(hasLetters && hasDigits)) {
      return (isValid: true, errorKey: 'auth.validation.password.weak', isWeak: true);
    }
    
    return (isValid: true, errorKey: 'auth.validation.password.valid', isWeak: false);
  }

  /// Validates document number: must not be empty
  static String? validateDocNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'auth.validation.docNumber';
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
