import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ErrorView extends StatelessWidget {
  final FlutterErrorDetails errorDetails;

  const ErrorView({super.key, required this.errorDetails});

  @override
  Widget build(BuildContext context) {
    // Determine language from context or a default
    // Since this is a global backup, we attempt to get locale but fallback to English.
    final locale = Localizations.maybeLocaleOf(context);
    final isBn = locale?.languageCode == 'bn';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 64,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                isBn ? 'দুঃখিত, কিছু ভুল হয়েছে' : 'Oops! Something went wrong',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                isBn
                    ? 'আমরা অ্যাপটি উন্নত করতে কাজ করছি। অনুগ্রহ করে পুনরায় চেষ্টা করুন বা আমাদের জানান।'
                    : 'We are working to improve the app. Please try again or let us know.',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Refresh app or go back safely
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(isBn ? 'পুনরায় চেষ্টা করুন' : 'Try Again'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 24),
                ExpansionTile(
                  title: const Text('Error Details (Debug Mode Only)'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        errorDetails.exception.toString(),
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
