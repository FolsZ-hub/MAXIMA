import 'package:flutter_test/flutter_test.dart';
import 'package:maxima_rpg/models/dungeon.dart';

void main() {
  group('Dungeon', () {
    test('default dungeons have correct IDs matching backend', () {
      final dungeons = Dungeon.getDefaultDungeons();

      expect(dungeons.length, 3);

      final ids = dungeons.map((d) => d.dungeonId).toList();
      expect(ids, contains('catacumbas_del_novato'));
      expect(ids, contains('laberinto_obsidiana'));
      expect(ids, contains('abismo_dragon_negro'));
    });

    test('difficulty values match backend format', () {
      final dungeons = Dungeon.getDefaultDungeons();

      expect(dungeons[0].difficulty, 'easy');
      expect(dungeons[1].difficulty, 'medium');
      expect(dungeons[2].difficulty, 'hard');
    });

    test('fromJson/toJson roundtrip', () {
      final json = {
        'dungeonId': 'test_dungeon',
        'name': 'Mazmorra Test',
        'difficulty': 'medium',
        'description': 'Una mazmorra de prueba.',
        'imagePath': 'assets/test.png',
        'reward': 100,
        'minLevel': 5,
      };

      final dungeon = Dungeon.fromJson(json);
      final output = dungeon.toJson();

      expect(output['dungeonId'], 'test_dungeon');
      expect(output['name'], 'Mazmorra Test');
      expect(output['difficulty'], 'medium');
      expect(output['reward'], 100);
      expect(output['minLevel'], 5);
    });
  });

  group('DungeonPath', () {
    test('fromJson creates path correctly', () {
      final json = {'targetRoomIndex': 3, 'description': 'Un pasillo oscuro.'};
      final path = DungeonPath.fromJson(json);

      expect(path.targetRoomIndex, 3);
      expect(path.description, 'Un pasillo oscuro.');
    });

    test('toJson serializes correctly', () {
      const path = DungeonPath(targetRoomIndex: 2, description: 'Escaleras.');
      final json = path.toJson();

      expect(json['targetRoomIndex'], 2);
      expect(json['description'], 'Escaleras.');
    });
  });

  group('DungeonTrap', () {
    test('fromJson creates trap correctly', () {
      final json = {'name': 'Pinchos', 'damage': 15, 'type': 'physical'};
      final trap = DungeonTrap.fromJson(json);

      expect(trap.name, 'Pinchos');
      expect(trap.damage, 15);
      expect(trap.type, 'physical');
    });
  });

  group('DungeonMerchant', () {
    test('fromJson creates merchant correctly', () {
      final json = {
        'name': 'Rodrigo',
        'greeting': 'Bienvenido!',
        'items': [
          {'name': 'Pocion', 'price': 10},
        ],
        'itemCount': 1,
      };
      final merchant = DungeonMerchant.fromJson(json);

      expect(merchant.name, 'Rodrigo');
      expect(merchant.items.length, 1);
      expect(merchant.items[0]['name'], 'Pocion');
    });
  });

  group('DungeonRoom', () {
    test('fromJson creates room with all fields', () {
      final json = {
        'id': 'room_0',
        'index': 0,
        'type': 'corridor',
        'description': 'Un pasillo largo.',
        'enemies': [
          {'name': 'Rata', 'hp': 15},
        ],
        'loot': {'coins': 10},
        'trap': {'name': 'Pinchos', 'damage': 5, 'type': 'physical'},
        'isRest': false,
        'paths': [
          {'targetRoomIndex': 1, 'description': 'Norte'},
        ],
      };

      final room = DungeonRoom.fromJson(json);

      expect(room.id, 'room_0');
      expect(room.type, 'corridor');
      expect(room.enemies.length, 1);
      expect(room.trap?.name, 'Pinchos');
      expect(room.paths.length, 1);
      expect(room.paths[0].targetRoomIndex, 1);
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'room_1',
        'index': 1,
        'type': 'rest',
        'description': 'Descanso.',
        'isRest': true,
        'healAmount': 20,
      };

      final room = DungeonRoom.fromJson(json);

      expect(room.trap, isNull);
      expect(room.merchant, isNull);
      expect(room.loot, isNull);
      expect(room.isRest, true);
      expect(room.healAmount, 20);
      expect(room.enemies, isEmpty);
      expect(room.paths, isEmpty);
    });
  });

  group('DungeonState', () {
    test('fromJson creates state with rooms', () {
      final json = {
        'dungeonId': 'catacumbas_del_novato',
        'name': 'Catacumbas del Novato',
        'difficulty': 'easy',
        'rooms': [
          {
            'id': 'room_0',
            'index': 0,
            'type': 'corridor',
            'description': 'Entrada.',
            'paths': [
              {'targetRoomIndex': 1, 'description': 'Adelante'},
            ],
          },
          {
            'id': 'room_1',
            'index': 1,
            'type': 'boss',
            'description': 'Jefe.',
          },
        ],
        'currentRoom': 0,
        'completed': false,
      };

      final state = DungeonState.fromJson(json);

      expect(state.dungeonId, 'catacumbas_del_novato');
      expect(state.rooms.length, 2);
      expect(state.currentRoom, 0);
      expect(state.completed, false);
    });

    test('mutable fields can be updated', () {
      final state = DungeonState(
        dungeonId: 'test',
        name: 'Test',
        difficulty: 'easy',
        rooms: [],
      );

      state.currentRoom = 3;
      state.completed = true;

      expect(state.currentRoom, 3);
      expect(state.completed, true);
    });

    test('toJson serializes correctly', () {
      final state = DungeonState(
        dungeonId: 'test',
        name: 'Test',
        difficulty: 'easy',
        rooms: [
          const DungeonRoom(
            id: 'r0',
            index: 0,
            type: 'corridor',
            description: 'Test room',
          ),
        ],
        createdAt: '2026-02-14T00:00:00Z',
      );

      final json = state.toJson();
      expect(json['dungeonId'], 'test');
      expect((json['rooms'] as List).length, 1);
      expect(json['createdAt'], '2026-02-14T00:00:00Z');
    });
  });
}
