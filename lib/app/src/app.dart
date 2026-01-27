import 'dart:io';

import 'package:aaatp/views/components/src/show_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_window_close/flutter_window_close.dart';
import 'package:provider/provider.dart';
import '/views/views.dart';
import '/utils/utils.dart';
import '/theme/theme.dart';
import '/app/app.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> messengerKey =
    GlobalKey<ScaffoldMessengerState>();

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final ShowDialogs showDialogs = ShowDialogs();

  @override
  void initState() {
    super.initState();

    if (Platform.isWindows) {
      FlutterWindowClose.setWindowShouldCloseHandler(() async {
        final ctx = navigatorKey.currentContext;
        if (ctx == null) return true;

        bool? shouldExit = await showDialogs.showExitConfirmationDialog(ctx);

        if (shouldExit == true) {
          exit(0);
        }

        return shouldExit;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => const ConfirmDialog(
            title: 'Exit App',
            content: 'Are you sure you want to exit the application?',
            successText: 'Exit',
            cancelText: 'Cancel',
          ),
        );

        if (shouldExit == true) {
          Navigator.of(context).pop(); // exits app
        }
      },
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (context) => AuthProvider()..checkLoginStatus(),
          ),
          ChangeNotifierProvider(create: (context) => MessageProvider()),
          ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ],
        child: Consumer2<AuthProvider, ThemeProvider>(
          builder: (context, authProvider, themeProvider, child) {
            return AnimatedTheme(
              data: themeProvider.themeMode == ThemeMode.dark
                  ? darkTheme
                  : lightTheme,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
      
              child: MaterialApp(
                navigatorKey: navigatorKey,
                scaffoldMessengerKey: messengerKey,
                debugShowCheckedModeBanner: false,
                title: "AAATP",
                theme: lightTheme,
      
                // darkTheme: darkTheme,
                // themeMode: themeProvider.themeMode,
                home: authProvider.isLoggedIn
                    ? authProvider.homeWidget ?? Container()
                    : const Splash(),
              ),
            );
          },
        ),
      ),
    );
  }
}
