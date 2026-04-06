import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fake_news_detector/core/theme/app_theme.dart';
import 'package:fake_news_detector/providers/analysis_provider.dart';
import 'package:fake_news_detector/presentation/screens/home_screen.dart';
import 'package:fake_news_detector/presentation/screens/result_screen.dart';
import 'package:fake_news_detector/presentation/screens/history_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FakeNewsDetectorApp());
}

class FakeNewsDetectorApp extends StatelessWidget {
  const FakeNewsDetectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AnalysisProvider(),
      child: MaterialApp(
        title: 'Fake News Detector',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/result': (context) => const ResultScreen(),
          '/history': (context) => const HistoryScreen(),
        },
      ),
    );
  }
}

