class Validation {
  static String? commonValidation({
    required String? input,
    required String label,
    int? length,
    required bool isReq,
  }) {
    if (isReq) {
      if (input != null) {
        if (input.isEmpty) {
          return "$label is required";
        }
        if (length != null) {
          if (input.length < length) {
            return "$label must be at least $length characters long";
          }
        }
      }
    }
    return null;
  }

  static String? validEmail({required String? input, bool? isReq}) {
    if (input != null) {
      if (isReq ?? false) {
        if (input.isEmpty) {
          return 'Email is required';
        }
      }
      if (input.isNotEmpty) {
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(input)) {
          return 'Invalid email address';
        }
      }
    }

    return null;
  }

  static String? validUrl({required String input, bool? isReq}) {
    if (isReq ?? false) {
      if (input.isEmpty) {
        return 'Url is required';
      }
    }
    if (input.isNotEmpty) {
      if (!RegExp(r'^(http|https)://[^\s/$.?#].[^\s]*$').hasMatch(input)) {
        return 'Invalid url';
      }
    }
    return null;
  }

  static String? passwordValidation({
    required String? input,
    required bool isReq,
  }) {
    if (input != null) {
      if (input.length < 8) {
        return "Must be at least 8 characters long";
      }

      if (!RegExp(r'[A-Z]').hasMatch(input)) {
        return "Must contain at least one uppercase letter";
      }

      if (!RegExp(r'[a-z]').hasMatch(input)) {
        return "Must contain at least one lowercase letter";
      }

      if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(input)) {
        return "Must contain at least one special character";
      }

      if (!RegExp(r'\d').hasMatch(input)) {
        return "Must contain at least one number";
      }
    }

    return null;
  }

  static String? validAddress({required String input, bool isReq = false}) {
    if (isReq && input.isEmpty) {
      return 'Address is required';
    }

    if (input.isNotEmpty) {
      if (input.length > 150) {
        return 'Address is too long (max 150 characters)';
      }

      if (!RegExp(r'^[a-zA-Z0-9\s,.\-#/]+$').hasMatch(input)) {
        return 'Invalid characters in address';
      }
    }

    return null;
  }

  static String? validMobileNumber({
    required String? input,
    bool isReq = false,
  }) {
    if (isReq && (input == null || input.isEmpty)) {
      return 'Mobile number is required';
    }

    if (input != null && input.isNotEmpty) {
      if (input.length != 10) {
        return 'Mobile number must be 10 digits';
      }

      if (!RegExp(r'^[0-9]+$').hasMatch(input)) {
        return 'Mobile number must contain only digits';
      }
    }

    return null;
  }

  static String? validName({
    required String? input,
    String label = 'Name',
    bool isReq = true,
  }) {
    if (isReq && (input == null || input.isEmpty)) {
      return '$label is required';
    }

    if (input != null && input.isNotEmpty) {
      if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(input)) {
        return '$label must contain only alphabets';
      }
    }

    return null;
  }

  static String? validGstVat({required String? input, bool isReq = false}) {
    if (isReq && (input == null || input.isEmpty)) {
      return 'GST/VAT number is required';
    }

    if (input != null && input.isNotEmpty) {
      if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(input)) {
        return 'GST/VAT must contain only alphanumeric characters';
      }
    }

    return null;
  }

  static String? validPostalCode({required String? input, bool isReq = false}) {
    if (isReq && (input == null || input.isEmpty)) {
      return 'Postal code is required';
    }

    if (input != null && input.isNotEmpty) {
      if (!RegExp(r'^[a-zA-Z0-9\s-]+$').hasMatch(input)) {
        return 'Invalid postal code format';
      }
    }

    return null;
  }
}
