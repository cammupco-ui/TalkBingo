
import 'package:talkbingo_app/utils/url_cleaner_stub.dart'
    if (dart.library.html) 'package:talkbingo_app/utils/url_cleaner_web.dart';

class UrlCleaner {
  static void removeCodeParam() {
    removeCodeParamImpl();
  }
}
