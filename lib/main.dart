import 'package:flutter/material.dart';

void main() {
  runApp(const GyanHubApp());
}

class GyanHubApp extends StatelessWidget {
  const GyanHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gyan Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const ComingSoonScreen(),
    );
  }
}

class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF6C63FF),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    size: 52,
                    color: Color(0xFF6C63FF),
                  ),
                ),

                const SizedBox(height: 32),

                // App name
                const Text(
                  'Gyan Hub',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 12),

                // Tagline
                const Text(
                  'Your Learning, Evolved.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF6C63FF),
                    letterSpacing: 0.8,
                  ),
                ),

                const SizedBox(height: 48),

                // Coming soon badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF9C67FF)],
                    ),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Text(
                    '🚀  Coming Soon',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Sub message
                const Text(
                  'We are building something amazing.\nStay tuned!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white54,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
