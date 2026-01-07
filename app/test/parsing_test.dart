
import 'package:test/test.dart';

void main() {
  test('Supabase Question Parsing Logic Verification', () {
    // 1. Mock Supabase Response (List<Map<String, dynamic>>)
    final List<Map<String, dynamic>> mockResponse = [
      {
        'content': 'Question 1',
        'type': 'B',
        'code_names': ['T25-001'],
        'details': {
          'choice_a': 'Option A',
          'choice_b': 'Option B',
        }
      },
      {
        'content': 'Question 2',
        'type': 'T',
        'code_names': ['T25-002'],
        'details': {
          'answers': 'The Truth',
        }
      },
      {
        'content': 'Question 3',
        'type': 'M',
        'code_names': ['T25-003'],
        'details': {
          'game_code': 'DICE_ROLL',
        }
      },
      {
        'content': 'Question 4 (No Details)',
        'type': 'B',
        'code_names': ['T25-004'],
        // 'details' is null or missing in DB
      }
    ];

    // 2. Logic extracted from GameSession.dart
    final List<String> questions = mockResponse.map<String>((q) {
      return q['content'] as String;
    }).toList();

    final List<Map<String, dynamic>> options = mockResponse.map<Map<String, dynamic>>((q) {
      final details = q['details'] ?? {};
      return {
        'type': q['type'] ?? 'B',
        'A': details['choice_a'] ?? '',
        'B': details['choice_b'] ?? '',
        'answer': details['answers'] ?? '',
        'game_code': details['game_code'] ?? '',
      };
    }).toList();

    // 3. Assertions
    expect(questions.length, 4);
    expect(questions[0], 'Question 1');

    // Balance Question
    expect(options[0]['type'], 'B');
    expect(options[0]['A'], 'Option A');
    expect(options[0]['B'], 'Option B');

    // Truth Question
    expect(options[1]['type'], 'T');
    expect(options[1]['answer'], 'The Truth');

    // MiniGame
    expect(options[2]['type'], 'M');
    expect(options[2]['game_code'], 'DICE_ROLL');

    // Robustness (Missing details)
    expect(options[3]['type'], 'B');
    expect(options[3]['A'], '');
    expect(options[3]['B'], '');

    print('Parsing logic verified successfully!');
  });
}
