import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sweat_pets/game/pet_sprite.dart';
import 'package:sweat_pets/models/evolution_system.dart';

class TestGame extends FlameGame {
  @override
  Future<void> onLoad() async {
    await super.onLoad();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('PetSprite', () {
    test('initializes with correct level', () {
      final sprite = PetSprite(
        level: 3,
        position: Vector2(100, 100),
        size: Vector2(50, 50),
      );
      
      expect(sprite.level, 3);
    });
    
    test('updates level correctly', () {
      final sprite = PetSprite(
        level: 0,
        position: Vector2(100, 100),
        size: Vector2(50, 50),
      );
      
      sprite.updateLevel(2);
      expect(sprite.level, 2);
      
      // Should clamp to max level
      sprite.updateLevel(EvolutionSystem.maxLevel + 5);
      expect(sprite.level, EvolutionSystem.maxLevel);
    });
    
    test('position and size are set correctly', () {
      final position = Vector2(100, 100);
      final size = Vector2(50, 50);
      
      final sprite = PetSprite(
        level: 0,
        position: position,
        size: size,
      );
      
      expect(sprite.position, position);
      expect(sprite.size, size);
    });
  });
} 