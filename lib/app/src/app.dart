import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/views/views.dart';
import '/utils/utils.dart';
import '/theme/theme.dart';
import '/app/app.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> messengerKey =
    GlobalKey<ScaffoldMessengerState>();

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
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
    );
  }
}
