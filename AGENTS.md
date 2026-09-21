# AI Agent Guidelines

Last updated: 2026-09-22

---

## Project

**cloudinary** is a complete Cloudinary SDK for Dart and Flutter. It is pure Dart on purpose: no Flutter dependency, so the same package serves a Flutter app, a Dart backend and a CLI.

| Area          | Detail                                                                                 |
| ------------- | -------------------------------------------------------------------------------------- |
| Language      | Dart 3, pure Dart, SDK `^3.8.0`                                                |
| Runtime deps  | two: `http` and `crypto`. A third needs explicit approval                              |
| Tests         | `package:test` with `package:http`'s `MockClient`; golden vectors for signing and URLs |
| Lint / format | `package:lints` recommended, plus `avoid_print` and `public_member_api_docs`           |
| Publishing    | pub.dev, tag-triggered via the `PUB_RELEASE_TOKEN` secret                              |

### Layout

```
lib/
  cloudinary.dart                 public barrel; exports nothing from package:http
  src/
    cloudinary.dart               the Cloudinary facade, wiring groups to a transport
    exceptions.dart               sealed CloudinaryException hierarchy
    config/                       credentials, delivery options, CLOUDINARY_URL parsing
    auth/                         signing, auth tokens, webhook verification, SignatureProvider
    http/                         transport, retry policy, streamed multipart, file sources
    api/upload_api.dart           the Upload API
    api/admin/                    ten Admin groups, one file per resource family
    api/search/                   search execution and the chainable query builder
    url/                          transformations, distribution domains, URL assembly
    models/                       typed responses, each exposing a raw map
test/
  golden/                         signature, auth token and URL vectors
  api/, http/, config/, models/   per-area unit tests over MockClient
```

Every model extends `CloudinaryModel` and exposes `raw`. Parsing is total: a missing or malformed field degrades to null rather than throwing, so a new Cloudinary field is reachable through `raw` immediately instead of after a release here. Do not add strict parsing that can throw.

### The checks

`dart format --output=none --set-exit-if-changed .`, `dart analyze`, `dart test`, `dart pub publish --dry-run`. CI runs the first three in the `build` job. `.githooks/pre-push` runs them too (`git config core.hooksPath .githooks`).

### Conventions

- Conventional Commits, imperative subject `<=` 50 chars, no trailing period, no `Co-Authored-By` or `Generated with` trailers.
- Every PR that changes anything users receive bumps `pubspec.yaml` and adds a matching `CHANGELOG.md` entry. CI gate `version bumped` enforces both, and pub.dev rejects a publish with no changelog entry.
- The PR title becomes the squash commit message.
- `master` is protected: PR required, squash-only merges.
- The README documents **shipped features only** - no roadmap, no plans.
- Markdown prose is never hard-wrapped: one line per paragraph and per list item. Do not re-wrap these files to a column.
- Never use an em-dash. Use a hyphen.

### Things that will bite you

- **Timestamps are UNIX seconds.** Milliseconds make every signed request fail. `cloudinaryTimestamp()` is the only correct source.
- **Signature parameters sort by key**, not by the joined `key=value` string. The two diverge when one key prefixes another.
- **Signature version 2 escapes `&`.** That is what stops a parameter value from smuggling extra parameters into the signed string. Do not "simplify" it away.
- **Never guard with `assert`.** Release builds strip asserts, so a stripped guard would let an unauthenticated request reach Cloudinary. Throw `CloudinaryConfigException` instead.
- **`buildUri` hands `Uri.https` an unencoded path.** Pre-encoding double-escapes, turning a space in a folder name into `%2520`.
- **Admin auth is a header**, never credentials in the URL.
- Transformations serialize in short-key alphabetical order, which is what Cloudinary's own SDKs emit and what the URL signature is computed over.

---

## Always-Active Instructions

> These apply to EVERY interaction, automatically.

### Working Discipline

> Behavioral guidelines to reduce common LLM coding mistakes. Bias toward caution over speed; for trivial tasks, use judgment.

#### 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:

- Read existing code and understand patterns before proposing changes.
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

#### 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

#### 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:

- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

#### 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:

- "Add validation" -> "Write tests for invalid inputs, then make them pass"
- "Fix the bug" -> "Write a test that reproduces it, then make it pass"
- "Refactor X" -> "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:

```
1. [Step] -> verify: [check]
2. [Step] -> verify: [check]
3. [Step] -> verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

#### 5. Report What Was Done

After completing work, state what changed and why - not just that it's done.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.

### Multi-Agent Safety Rules

- **Never** create/apply/drop git stash entries unless explicitly requested
- **Never** edit files in `node_modules/`, `vendor/`, or other dependency directories
- **Always** work on a dedicated branch when running concurrent agents
- **Never** force-push or rebase shared branches from an agent session
- **Verify** no other agent is modifying the same files before making changes

### Release Safety

- **Never** merge a PR or publish to pub.dev without explicit approval. Merging `master` triggers the tag and the pub.dev publish in one shot, and a published version number can never be reused or unpublished.
- A publish run can exit non-zero **after** publishing successfully. A red Publish check means "check pub.dev for the version" rather than "it failed".

---
