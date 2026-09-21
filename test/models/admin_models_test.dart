import 'package:cloudinary/cloudinary.dart';
import 'package:test/test.dart';

/// Reads every modelled getter. Cheap, and it catches a getter wired to the
/// wrong JSON key, which is the mistake these thin models actually make.
void main() {
  test('PingResult', () {
    const ok = PingResult.fromJson({'status': 'ok'});
    expect(ok.status, 'ok');
    expect(ok.isOk, isTrue);
    expect(const PingResult.fromJson({'status': 'down'}).isOk, isFalse);
  });

  test('UsageReport reads nested groups', () {
    const u = UsageReport.fromJson({
      'plan': 'Advanced',
      'last_updated': '2026-09-01T00:00:00Z',
      'credits': {'usage': 12.5, 'limit': 100, 'used_percent': 12.5},
      'storage': {'usage': 1024},
      'bandwidth': {'usage': 2048},
      'objects': {'usage': 42},
      'transformations': {'usage': 7},
    });

    expect(u.plan, 'Advanced');
    expect(u.lastUpdated, DateTime.utc(2026, 9, 1));
    expect(u.creditsUsage, 12.5);
    expect(u.creditsLimit, 100.0);
    expect(u.creditsUsedPercent, 12.5);
    expect(u.storageUsage, 1024.0);
    expect(u.bandwidthUsage, 2048.0);
    expect(u.objectCount, 42);
    expect(u.transformations, 7);
  });

  test('UsageReport tolerates missing groups', () {
    const u = UsageReport.fromJson({'plan': 'Free'});
    expect(u.creditsUsage, isNull);
    expect(u.objectCount, isNull);
  });

  test('ConfigResult', () {
    const c = ConfigResult.fromJson({
      'cloud_name': 'demo',
      'created_at': '2026-01-01T00:00:00Z',
      'settings': {'folder_mode': 'dynamic'},
    });
    expect(c.cloudName, 'demo');
    expect(c.createdAt, DateTime.utc(2026));
    expect(c.settings?['folder_mode'], 'dynamic');
  });

  test('AssetResource reads every modelled field', () {
    const a = AssetResource.fromJson({
      'public_id': 'trips/a',
      'asset_id': 'aid',
      'resource_type': 'image',
      'type': 'upload',
      'format': 'jpg',
      'version': 3,
      'width': 100,
      'height': 50,
      'bytes': 999,
      'created_at': '2026-09-01T10:00:00Z',
      'url': 'http://x/a.jpg',
      'secure_url': 'https://x/a.jpg',
      'folder': 'trips',
      'asset_folder': 'trips',
      'display_name': 'A',
      'tags': ['t'],
      'context': {'alt': 'x'},
      'metadata': {'m': 1},
      'access_mode': 'public',
      'derived': [
        {'id': 'd'},
      ],
      'accessed_at': '2026-09-02T10:00:00Z',
    });

    expect(a.publicId, 'trips/a');
    expect(a.assetId, 'aid');
    expect(a.resourceType, CloudinaryResourceType.image);
    expect(a.type, 'upload');
    expect(a.format, 'jpg');
    expect(a.version, 3);
    expect(a.width, 100);
    expect(a.height, 50);
    expect(a.bytes, 999);
    expect(a.createdAt, DateTime.utc(2026, 9, 1, 10));
    expect(a.url, startsWith('http://'));
    expect(a.secureUrl, startsWith('https://'));
    expect(a.folder, 'trips');
    expect(a.assetFolder, 'trips');
    expect(a.displayName, 'A');
    expect(a.tags, ['t']);
    expect(a.context, {'alt': 'x'});
    expect(a.metadata, {'m': 1});
    expect(a.accessMode, 'public');
    expect(a.derived, hasLength(1));
    expect(a.lastAccess, DateTime.utc(2026, 9, 2, 10));
  });

  test('ResourceListResult', () {
    const r = ResourceListResult.fromJson({
      'resources': [
        {'public_id': 'a'},
      ],
      'next_cursor': 'C',
      'total_count': 9,
      'rate_limit_allowed': 500,
      'rate_limit_remaining': 499,
    });

    expect(r.resources.single.publicId, 'a');
    expect(r.nextCursor, 'C');
    expect(r.totalCount, 9);
    expect(r.rateLimitAllowed, 500);
    expect(r.rateLimitRemaining, 499);
  });

  test('ResourceListResult with no resources key', () {
    const r = ResourceListResult.fromJson({});
    expect(r.resources, isEmpty);
    expect(r.nextCursor, isNull);
  });

  test('DeleteResourcesResult', () {
    const d = DeleteResourcesResult.fromJson({
      'deleted': {'a': 'deleted'},
      'deleted_counts': {'a': 1},
      'partial': true,
      'next_cursor': 'C',
    });

    expect(d.deleted['a'], 'deleted');
    expect(d.deletedCounts, {'a': 1});
    expect(d.partial, isTrue);
    expect(d.nextCursor, 'C');
    expect(const DeleteResourcesResult.fromJson({}).partial, isFalse);
  });

  test('Folder and FolderListResult', () {
    const f = FolderListResult.fromJson({
      'folders': [
        {'name': 'trips', 'path': 'a/trips', 'external_id': 'e'},
      ],
      'next_cursor': 'C',
      'total_count': 1,
    });

    expect(f.folders.single.name, 'trips');
    expect(f.folders.single.path, 'a/trips');
    expect(f.folders.single.externalId, 'e');
    expect(f.nextCursor, 'C');
    expect(f.totalCount, 1);
  });

  test('TagListResult', () {
    const t = TagListResult.fromJson({
      'tags': ['a'],
      'next_cursor': 'C',
    });
    expect(t.tags, ['a']);
    expect(t.nextCursor, 'C');
    expect(const TagListResult.fromJson({}).tags, isEmpty);
  });

  test('AdminAck', () {
    expect(const AdminAck.fromJson({'success': true}).isOk, isTrue);
    expect(const AdminAck.fromJson({'message': 'ok'}).isOk, isTrue);
    expect(const AdminAck.fromJson({'message': 'nope'}).isOk, isFalse);
    expect(const AdminAck.fromJson({'message': 'x'}).message, 'x');
  });

  test('toString includes the raw map', () {
    expect(
      const PingResult.fromJson({'status': 'ok'}).toString(),
      contains('status'),
    );
  });
}
