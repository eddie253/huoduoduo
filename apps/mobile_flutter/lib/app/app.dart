import 'package:flutter/material.dart';
import 'router.dart';

class DidiApp extends StatelessWidget {
  const DidiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Didi Express',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E)),
        useMaterial3: true
      )
    );
  }
}
