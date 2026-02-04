
import 'dart:html' as html;

void removeCodeParamImpl() {
  try {
    final uri = Uri.parse(html.window.location.href);
    if (uri.queryParameters.containsKey('code')) {
      final newUri = uri.replace(queryParameters: Map.from(uri.queryParameters)..remove('code'));
      html.window.history.replaceState({}, '', newUri.toString());
    }
  } catch (e) {
    // Ignore error
  }
}
