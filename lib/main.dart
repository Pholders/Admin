import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/navigation_provider.dart';
import 'screens/root_shell.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const PholdersAdminApp());
}

class PholdersAdminApp extends StatelessWidget {
  const PholdersAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
      ],
      child: MaterialApp(
        title: 'Pholders Admin',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        // RootShell watches NavigationProvider and swaps in the screen
        // matching the active sidebar route.
        home: const RootShell(),
      ),
    );
  }
}
