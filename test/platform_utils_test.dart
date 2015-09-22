@TestOn("vm")
library tekartik_io_tools.platform_utils_tests;

import 'package:test/test.dart';
import 'package:tekartik_io_tools/platform_utils.dart';
import 'dart:io';

void main() {
  group('platform_utils', () {


    test('dartVmBin', () async {
      // make sure it exists
      expect(new File(dartVmBin).existsSync(), isTrue);
    });



  });


}
