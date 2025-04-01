import 'package:flutter/material.dart';
import '../models/pet.dart';
import '../models/pet_collection.dart';
import '../models/pet_state.dart';

const kBackgroundColor = Color(0xFF1E1E1E);
const kAccentColor = Color(0xFFFFAA00);
const kCardColor = Color(0xFF2A2A2A);
const kTextColor = Color(0xFFF0F0F0);

class PetSelectionScreen extends StatefulWidget {
  final Function(Pet) onPetSelected;
  final VoidCallback onBackPressed;
  final PetState currentState;

  const PetSelectionScreen({
    Key? key,
    required this.onPetSelected,
    required this.onBackPressed,
    required this.currentState,
  }) : super(key: key);

  @override
  State<PetSelectionScreen> createState() => _PetSelectionScreenState();
}

class _PetSelectionScreenState extends State<PetSelectionScreen> {
  int _selectedPetIndex = 0;
  late List<Pet> _availablePets;
  late List<Pet> _lockedPets;

  @override
  void initState() {
    super.initState();
    _availablePets = PetCollection.getUnlockedPets(widget.currentState);
    _lockedPets = PetCollection.getLockedPets(widget.currentState);
  }

  @override
  Widget build(BuildContext context) {
    final allPets = [..._availablePets, ..._lockedPets]; 
    final selectedPet = _selectedPetIndex < allPets.length 
        ? allPets[_selectedPetIndex] 
        : allPets.first;
    final isLocked = _selectedPetIndex >= _availablePets.length;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Logo and title
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'SWEATPET',
                    style: TextStyle(
                      color: kAccentColor,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.favorite,
                    color: kTextColor,
                    size: 28,
                  ),
                ],
              ),
            ),

            // Choose your pet text
            Text(
              'CHOOSE YOUR PET',
              style: TextStyle(
                color: kTextColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // Pet showcase
            Container(
              height: 250,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: kAccentColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  allPets.length,
                  (index) => GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPetIndex = index;
                      });
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Pet selection indicator
                        if (_selectedPetIndex == index)
                          Container(
                            height: 160,
                            width: 110,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          
                        // Pet image
                        Opacity(
                          opacity: index >= _availablePets.length ? 0.6 : 1.0,
                          child: Hero(
                            tag: 'pet_${allPets[index].id}',
                            child: Image.asset(
                              'assets/pets/${allPets[index].id}${index >= _availablePets.length ? "0" : allPets[index].id == "machopet" ? "1" : "1"}.png',
                              height: 225,
                              width: 150,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                // If image not found, show colored box as fallback
                                return Container(
                                  height: 225,
                                  width: 150,
                                  decoration: BoxDecoration(
                                    color: allPets[index].baseColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      allPets[index].name.substring(0, 1),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 48,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        
                        // Lock overlay for locked pets
                        if (index >= _availablePets.length)
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.lock,
                                color: Colors.white.withOpacity(0.8),
                                size: 40,
                              ),
                              const SizedBox(height: 5),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Locked',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                        // Tap indicator
                        Positioned(
                          bottom: 0,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _selectedPetIndex == index 
                                ? Colors.white.withOpacity(0.6)
                                : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _selectedPetIndex == index ? 'Selected' : '',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Pet info
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kCardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        selectedPet.name,
                        style: TextStyle(
                          color: kTextColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isLocked)
                        Container(
                          margin: EdgeInsets.only(left: 8),
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.withOpacity(0.5))
                          ),
                          child: Text(
                            'LOCKED',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (!isLocked && _selectedPetIndex < _availablePets.length)
                        Container(
                          margin: EdgeInsets.only(left: 8),
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green.withOpacity(0.5))
                          ),
                          child: Text(
                            'AVAILABLE',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    selectedPet.description,
                    style: TextStyle(
                      color: kTextColor.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                  if (isLocked) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.lock_open,
                          color: kAccentColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Unlocks at ${selectedPet.unlockRequirements['totalSteps']} steps',
                          style: TextStyle(
                            color: kAccentColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${widget.currentState.totalSteps}',
                          style: TextStyle(
                            color: kTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          ' / ${selectedPet.unlockRequirements['totalSteps']} steps',
                          style: TextStyle(
                            color: kTextColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: widget.currentState.totalSteps / (selectedPet.unlockRequirements['totalSteps'] as int),
                        backgroundColor: kAccentColor.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(kAccentColor),
                        minHeight: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Keep walking to unlock this pet!',
                      style: TextStyle(
                        color: Colors.white70,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavButton(
                    Icons.arrow_back,
                    widget.onBackPressed,
                    "Back to main screen",
                  ),
                  _buildNavButton(
                    Icons.check,
                    isLocked
                        ? null // Disable button for locked pets
                        : () {
                            widget.onPetSelected(_availablePets[_selectedPetIndex]);
                          },
                    isLocked
                        ? "Locked pet - keep training!"
                        : "Select this pet",
                    isDisabled: isLocked,
                  ),
                  _buildNavButton(
                    Icons.info_outline,
                    () {
                      // Show detailed pet info
                      _showPetDetails(selectedPet);
                    },
                    "View pet details",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPetDetails(Pet pet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCardColor,
        title: Text(
          pet.name,
          style: TextStyle(
            color: kTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Evolution Levels',
              style: TextStyle(
                color: kAccentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(
              8,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: pet.evolutionColors[index],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Level $index',
                      style: TextStyle(
                        color: kTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CLOSE',
              style: TextStyle(
                color: kAccentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(IconData icon, VoidCallback? onPressed, String tooltip, {bool isDisabled = false}) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isDisabled ? kCardColor.withOpacity(0.5) : kCardColor,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(icon),
          color: isDisabled ? kTextColor.withOpacity(0.5) : kTextColor,
          onPressed: isDisabled ? null : onPressed,
        ),
      ),
    );
  }
} 