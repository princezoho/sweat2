import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sweat_pets/game/game_reference.dart';
import 'package:sweat_pets/game/sweat_pet_game.dart';
import 'package:sweat_pets/models/pet_state.dart';
import 'package:sweat_pets/screens/interface_screen.dart';
import 'package:sweat_pets/screens/splash_screen.dart';
import 'package:sweat_pets/models/user_profile.dart';
import 'package:sweat_pets/models/achievements.dart';
import 'package:sweat_pets/widgets/achievement_notification.dart';
import 'package:sweat_pets/screens/profile_screen.dart';
import 'package:sweat_pets/services/health_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load user profile with error handling
  UserProfile initialProfile;
  try {
    initialProfile = await UserProfile.load();
  } catch (e) {
    print('Error loading profile: $e');
    initialProfile = UserProfile.defaultProfile();
  }
  
  // Set preferred orientations to portrait only for stability
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  
  runApp(MyApp(initialProfile: initialProfile));
}

class MyApp extends StatelessWidget {
  final UserProfile initialProfile;
  
  const MyApp({
    Key? key,
    required this.initialProfile,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SweatPet',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
      ),
      // Show splash screen first, then handle game initialization in a simpler way
      home: SplashScreenWrapper(initialProfile: initialProfile),
    );
  }
}

// Simple wrapper to handle transition from splash to main screen
class SplashScreenWrapper extends StatefulWidget {
  final UserProfile initialProfile;
  
  const SplashScreenWrapper({Key? key, required this.initialProfile}) : super(key: key);
  
  @override
  State<SplashScreenWrapper> createState() => _SplashScreenWrapperState();
}

class _SplashScreenWrapperState extends State<SplashScreenWrapper> {
  bool _showSplash = true;
  
  @override
  void initState() {
    super.initState();
    
    // Navigate to main screen after a delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _initializeAndNavigate();
      }
    });
  }
  
  void _initializeAndNavigate() {
    // Get the active pet state or create a default one
    final activePetState = widget.initialProfile.activePetState ?? PetState.initial();
    
    // Initialize game
    final game = SweatPetGame(initialState: activePetState);
    final gameRef = GameReference(game);
    
    setState(() {
      _showSplash = false;
    });
    
    // Use Navigator to reduce the chance of build errors
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => InterfaceScreen(gameRef: gameRef),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}
