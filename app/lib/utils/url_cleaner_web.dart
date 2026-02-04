
import 'dart:html' as html;

void removeCodeParamImpl() {
  try {
    final currentUrl = html.window.location.href;
    var uri = Uri.parse(currentUrl);
    bool changed = false;

    // 1. Clean Query Params
    if (uri.queryParameters.containsKey('code')) {
      final newQueryParams = Map<String, String>.from(uri.queryParameters)..remove('code');
      uri = uri.replace(queryParameters: newQueryParams);
      changed = true;
    }

    // 2. Clean Fragment Params (Hash Routing)
    if (uri.fragment.contains('code=')) {
       // Simple Regex replacement for safety and speed
       // Matches ?code=XXXX or &code=XXXX
       String newFragment = uri.fragment.replaceAll(RegExp(r'([?&])code=[^&]+'), '');
       
       // Cleanup lingering '?' or '&' if needed? 
       // If we removed '?code=...', we might be left with empty string or other params
       // The regex `([?&])code=[^&]+` removes the separator too. 
       // We should be careful not to break other params.
       // Better: parse it if possible, but regex is okay if we are careful.
       
       // Regex: match `(?|&)code=[^&]*`
       newFragment = uri.fragment.replaceAll(RegExp(r'(?:\?|&)code=[^&]*'), '');
       
       // Determine if we need to fix the leading separator of the *next* param if it was the first
        // If query was `?code=1&foo=2` -> `&foo=2`. We need `?foo=2`.
       if (newFragment.contains('&') && !newFragment.contains('?')) {
          newFragment = newFragment.replaceFirst('&', '?');
       }
       
       uri = uri.replace(fragment: newFragment);
       changed = true;
    }

    if (changed) {
      html.window.history.replaceState({}, '', uri.toString());
    }
  } catch (e) {
    // Ignore error
  }
}
