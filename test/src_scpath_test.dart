library tekartik_io_tools.src_scpath_test;

import 'package:dev_test/test.dart';
import 'package:tekartik_io_tools/src/scpath.dart';

void main() {
  group('scpath', () {
    test('scUriToSubPath', () {
      expect(
          scUriToPathParts(
              "https://github.com/alextekartik/tekartik_io_tools.dart/"),
          ['github.com', 'alextekartik', 'tekartik_io_tools.dart']);

      expect(
          scUriToPathParts(
              "https://alextk@github.com/alextekartik/tekartik_io_tools.dart"),
          ['github.com', 'alextekartik', 'tekartik_io_tools.dart']);

      expect(scUriToPathParts("ssh://user@tekartik.com/~/sc"),
          ['tekartik.com', 'sc']);
    });
  });
}
