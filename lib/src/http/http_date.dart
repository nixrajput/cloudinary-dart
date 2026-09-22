const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

final RegExp _rfc1123 = RegExp(
  r'^[A-Za-z]{3},\s+(\d{1,2})\s+([A-Za-z]{3})\s+(\d{4})\s+'
  r'(\d{2}):(\d{2}):(\d{2})\s+GMT$',
);

/// Parses an RFC 1123 HTTP date, as used by `Retry-After` and Cloudinary's
/// rate-limit reset header, for example `Wed, 03 Sep 2026 09:00:00 GMT`.
///
/// Returns null when [value] is not in that form. Implemented here rather
/// than taken from `package:http_parser`, which would add a third runtime
/// dependency for one function.
DateTime? parseHttpDate(String value) {
  final match = _rfc1123.firstMatch(value.trim());
  if (match == null) return null;

  final month = _months.indexOf(match.group(2)!);
  if (month == -1) return null;

  return DateTime.utc(
    int.parse(match.group(3)!),
    month + 1,
    int.parse(match.group(1)!),
    int.parse(match.group(4)!),
    int.parse(match.group(5)!),
    int.parse(match.group(6)!),
  );
}
