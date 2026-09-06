import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_sprint/utils/build_info.dart';

/// Without --dart-define the build must say so rather than claim a commit it
/// cannot know. `flutter test` supplies no defines, so this is that case.
void main() {
  group('BuildInfo', () {
    test('reports an untracked build when no defines are supplied', () {
      expect(BuildInfo.isTracked, isFalse);
      expect(BuildInfo.commit, 'unknown');
      expect(BuildInfo.branch, 'unknown');
    });

    test('summary degrades to a local-build label', () {
      expect(BuildInfo.summary, 'dev · local build');
    });
  });
}
