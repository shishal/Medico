import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';

class MedicoApp extends StatelessWidget {
  const MedicoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medico',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // Follows the device light/dark setting automatically.
      themeMode: ThemeMode.system,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return Center(
              child: Text(
                'Hello',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            );
          },
        ),
      ),
    );
  }
}
