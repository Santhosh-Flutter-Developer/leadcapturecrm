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

  static String? passwordValidation({required String? input, required bool isReq}) {
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
}
