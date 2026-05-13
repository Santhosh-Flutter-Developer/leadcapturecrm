class Validation {
  static String? commonValidation({
    required String? input,
    required String label,
    int? length,
    required bool isReq,
  }) {
    final value = input?.trim() ?? '';

    if (isReq) {
      if (value.isEmpty) {
        return "$label is required";
      }

      if (length != null && value.length < length) {
        return "$label must be at least $length characters long";
      }
    }

    return null;
  }

  static String? validEmail({required String? input, bool? isReq}) {
    final value = input?.trim() ?? '';

    if (isReq ?? false) {
      if (value.isEmpty) {
        return 'Email is required';
      }
    }

    if (value.isNotEmpty) {
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
        return 'Invalid email address';
      }
    }

    return null;
  }

  static String? validUrl({required String input, bool? isReq}) {
    final value = input.trim();

    if (isReq ?? false) {
      if (value.isEmpty) {
        return 'Url is required';
      }
    }

    if (value.isNotEmpty) {
      if (!RegExp(r'^(http|https)://[^\s/$.?#].[^\s]*$').hasMatch(value)) {
        return 'Invalid url';
      }
    }

    return null;
  }

  static String? passwordValidation({
    required String? input,
    required bool isReq,
  }) {
    final value = input?.trim() ?? '';

    if (isReq && value.isEmpty) {
      return 'Password is required';
    }

    if (value.isNotEmpty) {
      if (value.length < 8) {
        return "Must be at least 8 characters long";
      }

      if (!RegExp(r'[A-Z]').hasMatch(value)) {
        return "Must contain at least one uppercase letter";
      }

      if (!RegExp(r'[a-z]').hasMatch(value)) {
        return "Must contain at least one lowercase letter";
      }

      if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
        return "Must contain at least one special character";
      }

      if (!RegExp(r'\d').hasMatch(value)) {
        return "Must contain at least one number";
      }
    }

    return null;
  }

  static String? validAddress({required String input, bool isReq = false}) {
    final value = input.trim();

    if (isReq && value.isEmpty) {
      return 'Address is required';
    }

    if (value.isNotEmpty) {
      if (value.length > 150) {
        return 'Address is too long (max 150 characters)';
      }

      if (!RegExp(r'^[a-zA-Z0-9\s,.\-#/]+$').hasMatch(value)) {
        return 'Invalid characters in address';
      }
    }

    return null;
  }
}
