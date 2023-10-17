import 'package:uuid/uuid.dart';

class UuidHandle {
  static const _uuid = Uuid();

  static String generate() {
    return _uuid.v4();
  }
}
