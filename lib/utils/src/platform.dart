import 'dart:io';

bool get kIsMobile => Platform.isAndroid || Platform.isIOS;

bool get kIsDesktop =>
    Platform.isWindows || Platform.isLinux || Platform.isMacOS;

bool get kIsWindows => Platform.isWindows;
