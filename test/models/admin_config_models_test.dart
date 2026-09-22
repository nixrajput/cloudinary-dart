import 'package:cloudinary/cloudinary.dart';
import 'package:test/test.dart';

void main() {
  test('TransformationInfo and listing', () {
    const list = TransformationListResult.fromJson({
      'transformations': [
        {
          'name': 'small',
          'allowed_for_strict': true,
          'allowed': true,
          'named': true,
          'used': 4,
          'info': [
            {'width': 100},
          ],
          'derived': [
            {'id': 'd'},
          ],
        },
      ],
      'next_cursor': 'C',
    });

    final t = list.transformations.single;
    expect(t.name, 'small');
    expect(t.allowed, isTrue);
    expect(t.named, isTrue);
    expect(t.usedBy, 4);
    expect(t.info, hasLength(1));
    expect(t.derived, hasLength(1));
    expect(list.nextCursor, 'C');
  });

  test('UploadPreset and listing', () {
    const list = UploadPresetListResult.fromJson({
      'presets': [
        {
          'name': 'mobile',
          'unsigned': true,
          'settings': {'folder': 'f'},
        },
      ],
      'next_cursor': 'C',
    });

    expect(list.presets.single.name, 'mobile');
    expect(list.presets.single.unsigned, isTrue);
    expect(list.presets.single.settings, {'folder': 'f'});
    expect(list.nextCursor, 'C');
  });

  test('UploadMapping and listing', () {
    const list = UploadMappingListResult.fromJson({
      'mappings': [
        {'folder': 'f', 'template': 'https://example.com'},
      ],
      'next_cursor': 'C',
    });

    expect(list.mappings.single.folder, 'f');
    expect(list.mappings.single.template, 'https://example.com');
    expect(list.nextCursor, 'C');
  });

  test('StreamingProfile and listing', () {
    const list = StreamingProfileListResult.fromJson({
      'data': [
        {
          'name': 'hd',
          'display_name': 'HD',
          'predefined': false,
          'representations': [
            {'transformation': 'w_1920'},
          ],
        },
      ],
    });

    final p = list.profiles.single;
    expect(p.name, 'hd');
    expect(p.displayName, 'HD');
    expect(p.predefined, isFalse);
    expect(p.representations, hasLength(1));
  });

  test('MetadataField including its datasource', () {
    const f = MetadataField.fromJson({
      'external_id': 'photographer',
      'type': 'enum',
      'label': 'Photographer',
      'mandatory': true,
      'default_value': 'unknown',
      'datasource': {
        'values': [
          {'external_id': 'a', 'value': 'Ana'},
        ],
      },
    });

    expect(f.externalId, 'photographer');
    expect(f.type, 'enum');
    expect(f.label, 'Photographer');
    expect(f.mandatory, isTrue);
    expect(f.defaultValue, 'unknown');
    expect(f.datasource, hasLength(1));
  });

  test('MetadataField without a datasource', () {
    const f = MetadataField.fromJson({'external_id': 'x'});
    expect(f.datasource, isNull);
  });

  test('MetadataRule', () {
    const r = MetadataRule.fromJson({
      'external_id': 'r',
      'metadata_field_id': 'f',
      'name': 'Rule',
      'condition': {'a': 1},
      'result': {'enable': true},
    });

    expect(r.externalId, 'r');
    expect(r.metadataFieldId, 'f');
    expect(r.name, 'Rule');
    expect(r.condition, {'a': 1});
    expect(r.result, {'enable': true});
  });

  test('metadata field types map to their wire names', () {
    expect(MetadataFieldType.enumeration.wireName, 'enum');
    expect(MetadataFieldType.string.wireName, 'string');
    expect(MetadataFieldType.integer.wireName, 'integer');
    expect(MetadataFieldType.date.wireName, 'date');
    expect(MetadataFieldType.set.wireName, 'set');
  });
}
