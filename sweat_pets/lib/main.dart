import 'package:flutter/material.dart';
import 'package:sweat_pets/game/sweat_pet_game.dart';
import 'package:sweat_pets/models/pet_state.dart';
import 'package:sweat_pets/widgets/step_input.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sweat Pets',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// Current pet state
  PetState _petState = PetState.initial();
  
  /// Game reference for updating
  SweatPetGame? _game;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Sweat Pets'),
      ),
      body: Column(
        children: [
          // Game widget (pet display)
          Expanded(
            flex: 3,
            child: SweatPetGameWidget(
              petState: _petState,
              backgroundColor: Colors.lightBlue.shade50,
              onGameCreated: (game) => _game = game,
            ),
          ),
          
          // Step input
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: StepInput(
              currentSteps: _petState.dailySteps,
              onStepsAdded: _addSteps,
            ),
          ),
          
          // Stats display
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'Level: ${_petState.currentLevel}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Total Steps: ${_petState.totalSteps}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _petState.getProgressToNextLevel(),
                  minHeight: 10,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                ),
                const SizedBox(height: 4),
                Text(
                  'Progress to Level ${_petState.currentLevel + 1}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Adds steps to the pet
  void _addSteps(int steps) {
    setState(() {
      final newState = _petState.addSteps(steps);
      _petState = newState;
      
      // Update game if available
      _game?.updatePetState(newState);
    });
  }
}
