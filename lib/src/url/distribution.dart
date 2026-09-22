import '../config/url_config.dart';
import '../exceptions.dart';
import 'crc32.dart';

/// Cloudinary's shared delivery hostname.
const String sharedCdnHost = 'res.cloudinary.com';

/// Builds the scheme and host a delivery URL starts with.
///
/// Mirrors Cloudinary's own resolution order: a secure distribution or CNAME
/// wins, a private CDN moves the cloud name into the hostname, and CDN
/// sharding rewrites `res` to `res-N` where N comes from a CRC-32 of the
/// source so one asset always lands on one shard.
String buildDistributionPrefix({
  required String cloudName,
  required String source,
  required UrlConfig config,
}) {
  final sharedDomain = !config.privateCdn;
  String prefix;

  if (config.secure) {
    var distribution =
        config.secureDistribution ??
        (config.privateCdn ? '$cloudName-res.cloudinary.com' : sharedCdnHost);

    if (config.cdnSubdomain && sharedDomain) {
      distribution = distribution.replaceFirst(
        sharedCdnHost,
        'res-${_shard(source)}.cloudinary.com',
      );
    }
    prefix = 'https://$distribution';
  } else if (config.cname != null) {
    final subdomain = config.cdnSubdomain ? 'a${_shard(source)}.' : '';
    prefix = 'http://$subdomain${config.cname}';
  } else {
    final cdnPart = config.privateCdn ? '$cloudName-' : '';
    final shardPart = config.cdnSubdomain ? '-${_shard(source)}' : '';
    prefix =
        'http://$cdnPart'
        'res$shardPart.cloudinary.com';
  }

  return sharedDomain ? '$prefix/$cloudName' : prefix;
}

/// Resolves the resource-type and delivery-type path segments.
///
/// Returns an empty list when [UrlConfig.useRootPath] removes them, and the
/// single segment `iu` when [UrlConfig.shorten] abbreviates `image/upload`.
List<String> resolveTypeSegments({
  required String resourceType,
  required String deliveryType,
  required UrlConfig config,
  String? urlSuffix,
}) {
  if (urlSuffix != null) {
    // An SEO suffix replaces the two type segments with a single plural,
    // rather than being appended to them. Cloudinary serves no other shape.
    final seo = _seoSegments[(resourceType, deliveryType)];
    if (seo == null) {
      throw CloudinaryConfigException(
        'A URL suffix is not supported for $resourceType/$deliveryType. '
        'Cloudinary allows it on image/upload, image/private, '
        'image/authenticated, raw/upload and video/upload.',
      );
    }
    return [seo];
  }

  if (config.useRootPath) return const [];

  if (config.shorten && resourceType == 'image' && deliveryType == 'upload') {
    return const ['iu'];
  }

  return [resourceType, deliveryType];
}

/// The single segment Cloudinary uses in place of `<type>/<delivery>` when a
/// URL suffix is present.
const Map<(String, String), String> _seoSegments = {
  ('image', 'upload'): 'images',
  ('image', 'private'): 'private_images',
  ('image', 'authenticated'): 'authenticated_images',
  ('raw', 'upload'): 'files',
  ('video', 'upload'): 'videos',
};

int _shard(String source) => (crc32(source) % 5) + 1;
