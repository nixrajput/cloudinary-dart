import '../../http/transport.dart';
import '../../models/admin_models.dart';

/// Environment-level Admin endpoints: reachability, usage and configuration.
class AccountApi {
  /// Creates an account API bound to [_transport].
  AccountApi(this._transport);

  final CloudinaryTransport _transport;

  /// Checks that Cloudinary is reachable and the credentials work.
  Future<PingResult> ping() async => PingResult.fromJson(
    await _transport.send(method: 'GET', segments: ['ping'], basicAuth: true),
  );

  /// Returns the usage report for the environment.
  ///
  /// Pass [date] to report on one specific day rather than the current
  /// period.
  Future<UsageReport> usage({DateTime? date}) async => UsageReport.fromJson(
    await _transport.send(
      method: 'GET',
      segments: ['usage', if (date != null) _formatDay(date)],
      basicAuth: true,
    ),
  );

  /// Returns the environment's configuration.
  Future<ConfigResult> config({bool? settings}) async => ConfigResult.fromJson(
    await _transport.send(
      method: 'GET',
      segments: ['config'],
      query: {'settings': ?settings},
      basicAuth: true,
    ),
  );

  /// Lists the resource types that have assets in this environment.
  Future<List<String>> resourceTypes() async {
    final json = await _transport.send(
      method: 'GET',
      segments: ['resources'],
      basicAuth: true,
    );
    final types = json['resource_types'];
    return types is List
        ? types.map((e) => e.toString()).toList(growable: false)
        : const [];
  }

  static String _formatDay(DateTime date) {
    final d = date.toUtc();
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$day-$month-${d.year}';
  }
}
