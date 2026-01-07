import 'package:flutter/foundation.dart';

class DevConfig {
  static final ValueNotifier<bool> isDevMode = ValueNotifier<bool>(false);

  static void toggle() {
    isDevMode.value = !isDevMode.value;
  }
}
