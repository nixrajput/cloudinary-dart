import 'package:cloudinary/cloudinary.dart';
import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'widgets.dart';

const _types = [
  ('CloudinaryApiException', 'Any error response, with its status and body.'),
  ('CloudinaryRateLimitException', '429 or 420, with the limit and reset.'),
  ('CloudinaryAuthException', '401 or 403: the key, secret or token.'),
  ('CloudinaryNotFoundException', '404: no such asset or resource.'),
  ('CloudinaryTransportException', 'The network failed or timed out.'),
  ('CloudinaryConfigException', 'Unusable settings, caught before sending.'),
  ('CloudinarySignatureException', 'Something could not be signed.'),
];

const _code = '''try {
  await cloudinary.upload.upload(file: source);
} on CloudinaryException catch (e) {
  switch (e) {
    case CloudinaryRateLimitException(:final resetAt):
      print('Slow down until \$resetAt');
    case CloudinaryAuthException():
      print('Check the API key and secret');
    case CloudinaryNotFoundException():
      print('No such asset');
    case CloudinaryApiException(:final statusCode, :final message):
      print('Cloudinary answered \$statusCode: \$message');
    case CloudinaryTransportException():
      print('Network trouble, after the retries ran out');
    case CloudinaryConfigException() || CloudinarySignatureException():
      print('Fix the setup: \${e.message}');
  }
}''';

/// The sealed exception family, two failures to trigger for real, and the
/// retry schedule computed from the default policy.
class ErrorsSection extends StatefulWidget {
  const ErrorsSection({super.key});

  @override
  State<ErrorsSection> createState() => _ErrorsSectionState();
}

class _ErrorsSectionState extends State<ErrorsSection>
    with AutomaticKeepAliveClientMixin {
  String? _caught;

  void _trigger(void Function() fails) {
    try {
      fails();
      setState(() => _caught = 'No exception');
    } on CloudinaryException catch (e) {
      setState(() => _caught = '$e');
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    const policy = RetryPolicy();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (name, meaning) in _types)
          Padding(
            padding: const EdgeInsets.only(bottom: Gaps.s),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$name  ',
                    style: const TextStyle(fontFamily: codeFont),
                  ),
                  TextSpan(
                    text: meaning,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: Gaps.s),
        Wrap(
          spacing: Gaps.s,
          runSpacing: Gaps.s,
          children: [
            OutlinedButton(
              onPressed: () =>
                  _trigger(() => Cloudinary.unsigned(cloudName: ' ')),
              child: const Text('Empty cloud name'),
            ),
            OutlinedButton(
              onPressed: () =>
                  _trigger(() => const AuthToken(key: 'a1b2c3d4').generate()),
              child: const Text('Token without an ACL'),
            ),
          ],
        ),
        if (_caught case final caught?) ...[
          const SizedBox(height: Gaps.m),
          CodeBlock(caught, label: 'the exception'),
        ],
        const Divider(height: Gaps.l * 2),
        Text('Retries', style: theme.textTheme.titleSmall),
        const SizedBox(height: Gaps.s),
        Text(
          'The default RetryPolicy makes ${policy.maxAttempts} attempts in '
          'all, retrying on ${policy.retryOn.join(', ')}. A Retry-After '
          'header always wins over the computed backoff.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: Gaps.m),
        Wrap(
          spacing: Gaps.l,
          runSpacing: Gaps.m,
          children: [
            for (var attempt = 1; attempt < policy.maxAttempts; attempt++)
              Reading(
                caption: 'After failure $attempt',
                value: '${policy.delayFor(attempt).inMilliseconds} ms',
              ),
          ],
        ),
        const SizedBox(height: Gaps.m),
        const CodeBlock(_code, label: 'the code'),
      ],
    );
  }
}
