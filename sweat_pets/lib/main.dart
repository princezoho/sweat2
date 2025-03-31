import 'package:flutter/material.dart';
import 'package:sweat_pets/game/sweat_pet_game.dart';
import 'package:sweat_pets/models/pet_state.dart';
import 'package:sweat_pets/widgets/enhanced_step_input.dart';
import 'package:sweat_pets/widgets/health_step_input.dart';
import 'package:sweat_pets/widgets/level_up_notification.dart';

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

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  /// Current pet state
  PetState _petState = PetState.initial();
  
  /// Game reference for updating
  SweatPetGame? _game;
  
  /// Whether to show the level up notification
  bool _showLevelUp = false;
  
  /// Previous level before adding steps
  int _previousLevel = 0;
  
  /// Tab controller
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _previousLevel = _petState.currentLevel;
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Sweat Pets'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.favorite),
              text: 'Health',
            ),
            Tab(
              icon: Icon(Icons.edit),
              text: 'Manual',
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
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
              
              // Tab views for step input methods
              Expanded(
                flex: 2,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Health integration tab
                    SingleChildScrollView(
                      child: HealthStepInput(
                        onStepsAdded: _addSteps,
                      ),
                    ),
                    
                    // Manual input tab
                    SingleChildScrollView(
                      child: EnhancedStepInput(
                        onStepsAdded: _addSteps,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Level up notification overlay
          if (_showLevelUp)
            Center(
              child: LevelUpNotification(
                newLevel: _petState.currentLevel,
                onDismissed: () {
                  setState(() {
                    _showLevelUp = false;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }
  
  /// Adds steps to the pet
  void _addSteps(int steps) {
    // Store current level before update
    final previousLevel = _petState.currentLevel;
    
    setState(() {
      final newState = _petState.addSteps(steps);
      _petState = newState;
      
      // Update game if available
      _game?.updatePetState(newState);
      
      // Check for level up and show notification
      if (newState.currentLevel > previousLevel) {
        _showLevelUp = true;
      }
    });
  }
}
