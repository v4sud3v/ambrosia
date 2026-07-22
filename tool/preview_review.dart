// Design preview harness for the Module 5 review card. Not shipped.
//   flutter run -d macos -t tool/preview_review.dart
import 'package:ambrosia/pipeline/explanation.dart';
import 'package:ambrosia/pipeline/extraction.dart';
import 'package:ambrosia/pipeline/review_screen.dart';
import 'package:ambrosia/theme/app_theme.dart';
import 'package:flutter/material.dart';

void main() => runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const ReviewScreen(
        extraction: Extraction(
          diagnosis: 'Viral fever',
          medicines: [
            Medicine(
              name: 'Paracetamol',
              dosage: '500 mg',
              frequency: 'twice a day',
              duration: '3 days',
            ),
          ],
          followUp: 'Review in 5 days if the fever does not settle',
        ),
        explanation: Explanation(
          condition:
              'You have a viral fever — your body is fighting off an infection. '
              'It usually clears on its own in a few days.',
          recovery:
              'Take the paracetamol when you feel hot or have body pain. '
              'Rest and drink plenty of warm fluids.',
          avoid: ['Cold drinks', 'Skipping meals', 'Heavy physical work'],
          dangerSigns: [
            'Fever above 103°F that will not come down',
            'Trouble breathing',
            'Rash or bleeding',
          ],
        ),
      ),
    ));
