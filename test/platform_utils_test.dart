@TestOn("vm")
library tekartik_io_tools.platform_utils_tests;

import 'package:dev_test/test.dart';
import 'package:tekartik_io_tools/platform_utils.dart';

void main() {
  group('platform', () {
    test('hostname', () async {
      expect(hostname, isNotNull);
    });
  });
}
