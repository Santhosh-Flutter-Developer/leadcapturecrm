import '/theme/theme.dart';
import '/models/models.dart';

class AppStrings {
  static const String updatePasswordUrl =
      "https://us-central1-srisoftwarez-crm.cloudfunctions.net/updateUserPassword";
  static const String deleteUserUrl =
      "https://us-central1-srisoftwarez-crm.cloudfunctions.net/deleteUserByEmail";

  static const String emptyProfilePhotoUrl =
      "https://firebasestorage.googleapis.com/v0/b/srisoftwarez-crm.firebasestorage.app/o/static%2Fuser-profile-icon-vector-avatar-600nw-2558760599.png?alt=media&token=bce08459-aba7-4773-b7dc-580369414bf7";

  static List<String> spokenLanguages = [
    "English",
    "Mandarin Chinese",
    "Hindi",
    "Spanish",
    "French",
    "Modern Standard Arabic",
    "Bengali",
    "Portuguese",
    "Russian",
    "Urdu",
    "Indonesian",
    "German",
    "Japanese",
    "Swahili",
    "Marathi",
    "Telugu",
    "Turkish",
    "Tamil",
    "Vietnamese",
    "Korean",
    "Italian",
    "Cantonese",
    "Thai",
    "Gujarati",
    "Polish",
    "Ukrainian",
    "Persian (Farsi)",
    "Malay",
    "Dutch",
    "Filipino (Tagalog)",
    "Romanian",
    "Pashto",
    "Malayalam",
    "Kannada",
    "Burmese",
    "Sindhi",
    "Nepali",
    "Sinhalese",
    "Czech",
    "Swedish",
    "Greek",
    "Hungarian",
    "Finnish",
    "Danish",
    "Norwegian",
    "Hebrew",
    "Lao",
    "Khmer",
    "Hausa",
    "Zulu",
    "Afrikaans",
    "Somali",
    "Amharic",
    "Bhojpuri",
    "Rajasthani",
    "Punjabi",
    "Assamese",
    "Odia",
    "Maithili",
    "Kashmiri",
    "Konkani",
    "Santali",
    "Tibetan",
    "Mongolian",
    "Serbian",
    "Croatian",
    "Slovak",
    "Bulgarian",
    "Bosnian",
    "Slovenian",
    "Albanian",
    "Latvian",
    "Lithuanian",
    "Estonian",
    "Icelandic",
    "Irish",
    "Welsh",
    "Scottish Gaelic",
    "Catalan",
    "Basque",
    "Galician",
    "Haitian Creole",
    "Luxembourgish",
    "Samoan",
    "Tongan",
    "Fijian",
    "Maori",
    "Khasi",
    "Dzongkha",
    "Tigrinya",
    "Yoruba",
    "Igbo",
    "Shona",
    "Chewa",
    "Xhosa",
  ];

  static List<String> accessPagesList = [
    "Admin",
    "Role",
    "Designation",
    "Department",
    "Sub Department",
    "Employees",
    "Lead Category",
    "Lead Source",
    "Lead Status",
    "Lead Priority",
    "Deal Status",
    "Chats",
    "Leads",
    "Deals",
    "Clients",
    "Projects",
    "Tasks",
    "Developer Area",
  ];

  static List<PermissionModel> permissionsTrueMap = List.generate(
    accessPagesList.length,
    (index) {
      return PermissionModel(
        page: accessPagesList[index],
        canView: true,
        canCreate: true,
        canDelete: true,
        canEdit: true,
      );
    },
  );
}

class PlaceholderImage {
  static String fetchImage(String letter) {
    final upper = letter.toUpperCase();
    // ignore: deprecated_member_use
    return "https://placehold.co/100x100/${LetterColors.getColor(upper).value.toRadixString(16).padLeft(8, '0').substring(2)}/FFFFFF/png?text=$upper";
  }
}
