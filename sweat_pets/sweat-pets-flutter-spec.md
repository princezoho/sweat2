
# Sweat Pets – Technical Specification

## Project Overview  
**Sweat Pets** is a Tamagotchi-style virtual pet game driven by the user’s physical activity. In this game, a cute creature grows stronger or weaker based on the number of steps the user takes. The initial prototype will be a mobile application built using Flutter and the Flame game engine that simulates step counts. Step counts are pulled from Apple HealthKit or Google Fit APIs using Flutter plugins, and influence the pet’s evolution, health, and achievements. The goal is to encourage exercise by linking real-world steps to the care and development of a virtual pet. 

### Key Features of the Prototype:
- **Local Web App:** Runs natively on iOS and Android. Step data is retrieved from device health APIs. No server or login is required for the prototype.
- **Step-Tracking Gameplay:** Users add “steps” manually to simulate walking. These steps feed into the pet’s growth mechanics (leveling up or down).
- **Virtual Pet Evolution:** The pet has multiple growth stages (like a classic Tamagotchi). Reaching certain step milestones will evolve the pet to a new stage; inactivity can cause it to regress or weaken.
- **Achievements System:** A set of fake achievements unlock as the user accumulates steps (e.g. first 100 steps, 1000 steps, etc.), providing goals and rewards.
- **Persistent State:** Game state is saved locally using ``shared_preferences`` so progress is retained between sessions.

## Prototype Platform and Data Persistence

### Platform:
- **Offline Play and Storage:** The app uses HTML5 Web Storage (``shared_preferences``) to persist data in the browser.
- **No Authentication:** No login or user accounts are needed. Each device maintains its own pet state, with future plans for optional cloud sync.
- **Browser Compatibility:** Targets modern browsers (Chrome, Safari, Firefox) on desktop and mobile.

### `shared_preferences` Schema:
- `totalSteps` – Integer value of total steps added.
- `currentLevel` – Current pet growth stage identifier.
- `achievements` – JSON array of unlocked achievements.
- `lastActive` – Timestamp of last user activity.

## Mobile Game Framework Selection

### Recommendation: **Flutter + Flame**
Flutter is ideal for mobile apps in 2025, offering great UI, native access to health data, and a clean dev experience.
Flame is a lightweight 2D game engine built specifically for Flutter, perfect for sprite animations, input, and game logic.
Phaser is the best match for sprite-based pet animations, game state logic, UI, and eventual mobile export via Cordova/Capacitor.

## Application Structure and Asset Management

### Folder Structure
```
/assets
   /creatures
       /A
           A1.png
           A2.png
           ...
   /ui
       button-add.png
       icon-trophy.png
```

### HTML/JS/CSS Breakdown
- **HTML:** Contains game container and basic UI.
- **CSS:** Styles UI layout and responsive design.
- **JS:** Phaser game logic, input handlers, and `shared_preferences` persistence.


## Game Logic: Step Input and Evolution

### Step Input
- Users manually input steps via form or buttons (in prototype).
- Game logic records both **daily step count** and **running average of daily steps**.
- `dailySteps` resets every 24 hours.
- `averageSteps` is updated at the end of each day using all prior daily step entries.

### Evolution System (Dual Layered)

#### 1. **Daily Evolution Level** (Temporary, resets daily)
- Based on `dailySteps`. Used to reflect how active the pet is **today**.
- Levels range from 0 to 5 (6 levels total).
     - Level 0: 0–999 avg steps
    - Level 1: 1,000–2,499 avg steps
    - Level 2: 2,500–4,999 avg steps
    - Level 3: 5,000–7,999 avg steps
    - Level 4: 8,000–9,999 avg steps
    - Level 5: 10,000–14,999 avg steps
    - Level 6: 15,000–19,999 avg steps
    - Level 7: 20,000+ avg steps


#### 2. **Average Evolution Level** (Persistent)
- Based on `averageSteps` across all previous days.
- Determines the **core evolution state** of the pet (appearance, strength, etc.).
- Levels range from 0 to 7 (8 levels total).
    - Level 0: 0–999 avg steps
    - Level 1: 1,000–2,499 avg steps
    - Level 2: 2,500–4,999 avg steps
    - Level 3: 5,000–7,999 avg steps
    - Level 4: 8,000–9,999 avg steps
    - Level 5: 10,000–14,999 avg steps
    - Level 6: 15,000–19,999 avg steps
    - Level 7: 20,000+ avg steps


### Inactivity Decay
- If `lastActive` exceeds 24 hours, pet may show signs of fatigue or minor regression.
- No permanent level loss on one missed day, but continued inactivity can reduce average steps.

### Optional Health/Happiness Meter
- Could be implemented as a simple bar or emoji indicator.


## Achievements System

### Examples:
- **First Steps** – Reach 100 steps
- **Walking Warrior** – 10,000 steps
- **Comeback** – Re-evolve after decay
- Stored in ``shared_preferences``, simple toast messages on unlock

## Roadmap: Flutter-Based Native App

### Phase 1: Web Prototype
- Phaser game with manual step input
- Store game state in ``shared_preferences``
- Test and iterate

### Phase 2: Polish
- Add production-quality artwork and animations
- Improve UI with Flutter widgets
- Add pet mood indicators and optional notifications

### Phase 3: HealthKit and Google Fit Integration
- Use Flutter's `health` plugin to connect with HealthKit and Google Fit
- Feed real step data into the pet evolution system
- Test across iOS and Android devices

### Phase 4: Advanced Features
- Push notifications using Flutter Local Notifications
- Add more pet types and moods
- Optional cloud sync and profile system

## Step Detection on Mobile Web

### Feasibility:
- **DeviceMotion API:** Accessible, but noisy and inconsistent
- **No Background Support:** Sensors only active when browser is open
- **Conclusion:** Not feasible for real pedometer use

## Summary Recommendations
- **Use Phaser 3** for the game engine
- **Use `shared_preferences`** for state
- **Design evolution stages** based on thresholds
- **Plan HealthKit integration** via Capacitor
- **Test on real devices** early
- **Don’t rely on browser sensors** for real steps

Sweat Pets is best built first as a local web game and later packaged as a mobile app with HealthKit support.
