import 'package:uuid/uuid.dart';

class IdService {
  static final _uuid = Uuid();

  static String generate() {
    return _uuid.v4();
  }
}
