import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  // ProviderScope is Riverpod's root: every provider lives under this widget.
  // Without it, ref.watch / Consumer widgets have nothing to read from.
  runApp(
    const ProviderScope(
      child: MedicoApp(),
    ),
  );
}
