/// Identifies the build running on a device.
///
/// The git values are injected at compile time with `--dart-define`; see
/// `scripts/build_apk.sh`, which reads them from the working tree. A build
/// made without those defines reports "unknown" rather than guessing, so a
/// hand-rolled `flutter build` is never mistaken for a tracked one.
abstract final class BuildInfo {
  static const String version =
      String.fromEnvironment('APP_VERSION', defaultValue: 'dev');

  /// Branch the APK was built from.
  static const String branch =
      String.fromEnvironment('GIT_BRANCH', defaultValue: 'unknown');

  /// Short commit SHA, suffixed with `-dirty` when the tree had uncommitted
  /// changes at build time — the usual case for a work-in-progress install.
  static const String commit =
      String.fromEnvironment('GIT_COMMIT', defaultValue: 'unknown');

  /// UTC build timestamp, to tell two builds of the same commit apart.
  static const String builtAt =
      String.fromEnvironment('BUILT_AT', defaultValue: 'unknown');

  static bool get isTracked => commit != 'unknown';

  /// One-line identifier, e.g. `1.0.0 · fix/exercise-state-reuse · c638649`.
  static String get summary =>
      isTracked ? '$version · $branch · $commit' : '$version · local build';
}
