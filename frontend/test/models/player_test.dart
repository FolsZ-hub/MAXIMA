import 'package:flutter_test/flutter_test.dart';
import 'package:maxima_rpg/models/player.dart';

void main() {
  group('Player', () {
    test('fromJson/toJson roundtrip preserves all fields', () {
      final json = {
        'uid': 'uid_001',
        'username': 'GuerreroSombrio',
        'smartCoins': 100,
        'legacyCharacters': ['char_1', 'char_2'],
        'settings': {'soundEnabled': true, 'notificationsEnabled': false},
        'activeCharacterId': 'char_1',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'lastLogin': '2026-02-14T12:00:00.000Z',
      };

      final player = Player.fromJson(json);
      final output = player.toJson();

      expect(output['uid'], 'uid_001');
      expect(output['username'], 'GuerreroSombrio');
      expect(output['smartCoins'], 100);
      expect((output['legacyCharacters'] as List).length, 2);
      expect(output['activeCharacterId'], 'char_1');
      expect(output['createdAt'], '2026-01-01T00:00:00.000Z');
      expect(output['lastLogin'], '2026-02-14T12:00:00.000Z');
    });

    test('new fields default to null', () {
      final player = Player(uid: 'u1', username: 'Test');

      expect(player.activeCharacterId, isNull);
      expect(player.createdAt, isNull);
      expect(player.lastLogin, isNull);
    });

    test('optional fields omitted from toJson when null', () {
      final player = Player(uid: 'u1', username: 'Test');
      final json = player.toJson();

      expect(json.containsKey('activeCharacterId'), false);
      expect(json.containsKey('createdAt'), false);
      expect(json.containsKey('lastLogin'), false);
    });

    test('copyWith overrides specified fields', () {
      final original = Player(
        uid: 'u1',
        username: 'Original',
        smartCoins: 50,
      );

      final copy = original.copyWith(
        username: 'Updated',
        smartCoins: 100,
        activeCharacterId: 'char_new',
      );

      expect(copy.username, 'Updated');
      expect(copy.smartCoins, 100);
      expect(copy.activeCharacterId, 'char_new');
      // Unchanged
      expect(copy.uid, 'u1');
    });

    test('default settings are applied', () {
      final player = Player(uid: 'u1', username: 'Test');

      expect(player.settings['soundEnabled'], true);
      expect(player.settings['notificationsEnabled'], true);
      expect(player.settings['serverUrl'], 'http://localhost:3000');
    });

    test('fromJson handles missing fields gracefully', () {
      final json = <String, dynamic>{};
      final player = Player.fromJson(json);

      expect(player.uid, '');
      expect(player.username, 'Desconocido');
      expect(player.smartCoins, 0);
      expect(player.legacyCharacters, isEmpty);
      expect(player.activeCharacterId, isNull);
    });
  });
}
