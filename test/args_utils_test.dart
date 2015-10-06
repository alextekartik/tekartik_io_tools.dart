@TestOn("vm")
library tekartik_io_tools.args_utils_test;

import 'package:tekartik_io_tools/args_utils.dart';
import 'io_test_common.dart';

void main() => defineTests();

void defineTests() {
  group('args', () {
    test('toDebugString', () async {
      expect(argsToDebugString(null), '');
      expect(argsToDebugString(null, false), '');
      expect(argsToDebugString([]), "");
      expect(argsToDebugString([], false), "");
      expect(argsToDebugString(["a"]), " a");
      expect(argsToDebugString(["a"], false), "a");
      expect(argsToDebugString(["a", "b"], false), "a b");
      expect(argsToDebugString(["a", "b c"], false), "a 'b c'");
    });
  });
}
