import 'dart:io';
import 'dart:convert';

void main() async {
  final file = File('missing_english_questions.csv');
  if (!await file.exists()) {
    print('missing_english_questions.csv not found');
    return;
  }

  final lines = await file.readAsLines();
  
  // Headers
  final balanceRows = <String>[];
  balanceRows.add('CodeName,Order,q_id,content,choice_a,choice_b,content_en,choice_a_en,choice_b_en');
  
  final truthRows = <String>[];
  truthRows.add('CodeName,Order,q_id,content,answers,content_en,answers_en');

  // Skip header row 0
  for (var i = 1; i < lines.length; i++) {
    final line = lines[i];
    if (line.trim().isEmpty) continue;

    // Parse line
    // Format: id,content,"{json}"
    // Find split between content and json
    // JSON field starts with "{""order""
    // So look for ',"{'
    
    int jsonStartIndex = line.lastIndexOf(',"{');
    if (jsonStartIndex == -1) {
      print('Skipping line $i: Cannot find JSON start');
      continue;
    }

    final leftPart = line.substring(0, jsonStartIndex);
    final jsonPartQuoted = line.substring(jsonStartIndex + 1); // "{...}"

    // Parse ID and Content
    int firstComma = leftPart.indexOf(',');
    if (firstComma == -1) {
       print('Skipping line $i: Cannot parse ID');
       continue;
    }
    
    String id = leftPart.substring(0, firstComma);
    String content = leftPart.substring(firstComma + 1);
    
    // Unquote content if needed
    if (content.startsWith('"') && content.endsWith('"')) {
      content = content.substring(1, content.length - 1);
      content = content.replaceAll('""', '"'); // Handle escaped quotes in content
    }

    // Parse JSON
    // Remove surrounding quotes "..."
    if (jsonPartQuoted.startsWith('"') && jsonPartQuoted.endsWith('"')) {
       String jsonInner = jsonPartQuoted.substring(1, jsonPartQuoted.length - 1);
       // Unescape double quotes
       jsonInner = jsonInner.replaceAll('""', '"');
       
       try {
         final details = jsonDecode(jsonInner) as Map<String, dynamic>;
         
         final qId = details['order']?.toString() ?? details['legacy_q_id']?.toString() ?? '';
         
         // Escape content for CSV
         final csvContent = _escapeCsv(content);
         final csvId = _escapeCsv(id);
         final csvQId = _escapeCsv(qId);
         
         if (details.containsKey('choice_a') || details.containsKey('choice_b')) {
           final choiceA = _escapeCsv(details['choice_a']?.toString() ?? '');
           final choiceB = _escapeCsv(details['choice_b']?.toString() ?? '');
           
           // CodeName uses ID (UUID)
           // Order uses qId
           balanceRows.add('$csvId,$csvQId,$csvQId,$csvContent,$choiceA,$choiceB,,,'); 
         } else {
           // Truth
           final answers = _escapeCsv(details['answers']?.toString() ?? '');
           truthRows.add('$csvId,$csvQId,$csvQId,$csvContent,$answers,,');
         }

       } catch (e) {
         print('Error parsing JSON at line $i: $e');
       }
    } else {
       print('Skipping line $i: JSON part not quoted as expected');
    }
  }

  await File('missing_balance.csv').writeAsString(balanceRows.join('\n'));
  await File('missing_truth.csv').writeAsString(truthRows.join('\n'));
  
  print('Done. Created missing_balance.csv (${balanceRows.length - 1} rows) and missing_truth.csv (${truthRows.length - 1} rows).');
}

String _escapeCsv(String value) {
  if (value.contains(',') || value.contains('"') || value.contains('\n')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}
