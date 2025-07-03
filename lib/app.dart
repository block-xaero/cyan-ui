import 'package:cyan/providers/router.dart';
import 'package:cyan/theme/cyan_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CyanApp extends ConsumerWidget {
  const CyanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Cyan',
      theme: CyanTheme.theme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
