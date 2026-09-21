/// Options controlling how delivery URLs are built.
///
/// Defaults match Cloudinary's own SDKs: HTTPS on the shared CDN, with a
/// synthetic `v1` inserted for public IDs containing a folder path so that
/// CDN caches invalidate correctly when an asset is overwritten.
class UrlConfig {
  /// Creates delivery URL options.
  const UrlConfig({
    this.secure = true,
    this.privateCdn = false,
    this.cname,
    this.secureDistribution,
    this.cdnSubdomain = false,
    this.shorten = false,
    this.useRootPath = false,
    this.forceVersion = true,
  });

  /// Whether to build `https` URLs. Defaults to true.
  final bool secure;

  /// Whether the account uses a private CDN distribution, which moves the
  /// cloud name into the hostname.
  final bool privateCdn;

  /// A custom domain for insecure delivery.
  final String? cname;

  /// A custom domain for secure delivery.
  final String? secureDistribution;

  /// Whether to shard requests across `res-1` to `res-5` subdomains, chosen by
  /// a CRC-32 of the public ID so a given asset always maps to one subdomain.
  final bool cdnSubdomain;

  /// Whether to abbreviate `image/upload` to `iu`.
  final bool shorten;

  /// Whether to omit the resource type and delivery type segments entirely.
  final bool useRootPath;

  /// Whether to insert `v1` when the public ID contains a folder path and no
  /// explicit version was given. Defaults to true.
  final bool forceVersion;

  /// Returns a copy with the given fields replaced.
  UrlConfig copyWith({
    bool? secure,
    bool? privateCdn,
    String? cname,
    String? secureDistribution,
    bool? cdnSubdomain,
    bool? shorten,
    bool? useRootPath,
    bool? forceVersion,
  }) => UrlConfig(
    secure: secure ?? this.secure,
    privateCdn: privateCdn ?? this.privateCdn,
    cname: cname ?? this.cname,
    secureDistribution: secureDistribution ?? this.secureDistribution,
    cdnSubdomain: cdnSubdomain ?? this.cdnSubdomain,
    shorten: shorten ?? this.shorten,
    useRootPath: useRootPath ?? this.useRootPath,
    forceVersion: forceVersion ?? this.forceVersion,
  );
}
