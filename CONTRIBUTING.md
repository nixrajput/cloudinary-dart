# Contributing to cloudinary

Thanks for your interest in contributing. cloudinary is a pure-Dart client for the whole Cloudinary API, and contributions that make it more complete, more correct or safer to use are very welcome.

## Code of Conduct

Please review and adhere to our [Code of Conduct](CODE_OF_CONDUCT.md). We expect all contributors to be respectful, considerate, and inclusive when interacting with the project and its community.

## Getting set up

Requires Dart 3.13 or newer (Flutter 3.47 or newer bundles it), and Flutter for the example app.

```bash
git clone https://github.com/nixrajput/cloudinary-dart.git
cd cloudinary-dart
flutter pub get
git config core.hooksPath .githooks   # optional: runs the checks below before each push
```

`flutter pub get` resolves the example app too. No Cloudinary account is needed: every test runs against `package:http`'s `MockClient`.

## The checks

Every one of these must pass before a PR can merge. CI runs all of them but the publish dry run, which the release workflow runs before every publish:

```bash
dart format --output=none --set-exit-if-changed .
dart analyze
dart test
dart test -p chrome                  # and again with -c dart2wasm
(cd example && flutter test)
dart pub publish --dry-run
```

CI also holds line coverage at 100% (`scripts/coverage.sh 100`), repeats analyze and test on Dart 3.13.0, the SDK floor, and builds the example app for Android, iOS, macOS, Windows, Linux, web and WebAssembly. A test that builds a signing client passes `allowSecretOnWeb: true`, or it throws in the browser runs.

## Workflow

1. **Fork and branch.** Branch off `master` with a descriptive name (`feat/streaming-profile-update`, `fix/signed-url-escaping`).
2. **Write the test first.** Every feature and bugfix lands with a test. Bugs get a test that reproduces them before the fix.
3. **Keep the diff surgical.** Every changed line should trace to the change you are making. No drive-by refactors, no speculative abstractions.
4. **Bump the version.** `pubspec.yaml` must move in every PR, with a matching `CHANGELOG.md` entry - CI enforces both (`version bumped`). Patch for fixes, minor for features.
5. **Update the docs.** If behaviour a user can see changes, the README changes in the same PR.
6. **Open the PR.** Fill in the template. The PR title becomes the squash commit message on merge, so write it in Conventional Commit form (`feat: add streaming profile updates`) and keep it under ~50 characters.

## Signing and golden vectors

Signatures, auth tokens and delivery URLs are pinned by golden vectors in `test/golden/`, derived from Cloudinary's own algorithm. When that behaviour changes on purpose, re-derive the vectors from the algorithm; never edit them to match the new output.

## Conventions

- **Commits:** Conventional Commits (`feat:`, `fix:`, `docs:`, `ci:`, `chore:`, `refactor:`), imperative subject, no trailing period.
- **Style:** `dart format` and the lints in `analysis_options.yaml`, including `public_member_api_docs`: every public API element carries a doc comment.
- **Language:** Dart `^3.13.0`, pure Dart. No Flutter dependency, so the package runs on servers, in Flutter apps and on the web.
- **Dependencies:** two runtime dependencies, `http` and `crypto`. Please do not add another without discussing it in an issue first.
- **Comments:** explain why, not what. Most code needs none.

## Reporting issues

Bugs and feature requests go to [Issues](https://github.com/nixrajput/cloudinary-dart/issues) - the templates ask for the affected area, the versions and a minimal repro, which is usually enough to act on. Redact your API secret, key and any live signed URL first. Questions and open-ended ideas belong in [Discussions](https://github.com/nixrajput/cloudinary-dart/discussions). Security issues follow [SECURITY.md](SECURITY.md) instead - never a public issue.

## Thank you

Every issue, repro, and PR makes this project more useful. Thanks for taking the time.
