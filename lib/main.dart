import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_fruit_machine/services/sound_service.dart';

void main() {
  runApp(const SlotMachineApp());
}

class SlotMachineApp extends StatelessWidget {
  const SlotMachineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Slot Machine',
      theme: ThemeData.dark(),
      home: const SlotMachineScreen(),
    );
  }
}

class SlotMachineScreen extends StatefulWidget {
  const SlotMachineScreen({super.key});

  @override
  State<SlotMachineScreen> createState() => _SlotMachineScreenState();
}

class _SlotMachineScreenState extends State<SlotMachineScreen> {
  // De 8 unieke plaatjes
  final List<String> _emojis = ['🍒', '🍋', '🍊', '🍉', '🔔', '💎', '7️⃣', '🍀'];

  // De basiswaardes per plaatje voor een Jackpot (wordt vermenigvuldigd met inzet)
  final Map<String, int> _baseJackpotValues = {
    '7️⃣': 50, // x inzet bij jackpot
    '💎': 30,
    '🔔': 15,
    '🍀': 10,
    '🍉': 8,
    '🍊': 6,
    '🍋': 5,
    '🍒': 4,
  };

  // Een gewogen lijst om de kansen te bepalen
  final List<String> _weightedPool = [
    '🍒',
    '🍒',
    '🍒',
    '🍒',
    '🍒',
    '🍒',
    '🍒',
    '🍒',
    '🍋',
    '🍋',
    '🍋',
    '🍋',
    '🍋',
    '🍋',
    '🍊',
    '🍊',
    '🍊',
    '🍊',
    '🍊',
    '🍉',
    '🍉',
    '🍉',
    '🍉',
    '🔔',
    '🔔',
    '🔔',
    '🍀',
    '🍀',
    '💎',
    '7️⃣',
  ];

  // HIER IS DE INITIALISATIE TOEGEVOEGD: De 3 inzetmogelijkheden
  final List<int> _betOptions = [10, 20, 50];

  // Controllers voor de 3 wielen
  final List<FixedExtentScrollController> _controllers = List.generate(
    3,
    (_) => FixedExtentScrollController(initialItem: 0),
  );

  bool _isSpinning = false;
  String _resultMessage = "Kies je inzet en spin!";

  int _score = 200; // Beginkapitaal
  int _currentBet = 10; // Standaard inzet

  void _spin() async {
    if (_isSpinning || _score < _currentBet) return;

    setState(() {
      _isSpinning = true;
      _score -= _currentBet;
      _resultMessage = "Wielen draaien...";
    });

    final random = Random();
    List<String> chosenItems = [];

    SoundService.instance.playSound("spin.mp3");

    for (int i = 0; i < 3; i++) {
      String pickedEmoji = _weightedPool[random.nextInt(_weightedPool.length)];
      chosenItems.add(pickedEmoji);

      int emojiIndex = _emojis.indexOf(pickedEmoji);
      int currentItem = _controllers[i].hasClients ? _controllers[i].selectedItem : 0;
      int extraSpins = (random.nextInt(3) + 4) * _emojis.length;
      int finalTarget = currentItem + extraSpins + (emojiIndex - (currentItem % _emojis.length));

      _controllers[i].animateToItem(
        finalTarget,
        duration: Duration(milliseconds: 1500 + (i * 300)),
        curve: Curves.easeOutCubic,
      );
    }

    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    setState(() {
      _isSpinning = false;

      String item0 = chosenItems[0];
      String item1 = chosenItems[1];
      String item2 = chosenItems[2];

      if (item0 == item1 && item1 == item2) {
        int baseWin = _baseJackpotValues[item0] ?? 5;
        int winAmount = baseWin * _currentBet;
        _score += winAmount;
        _resultMessage = "🎉 JACKPOT! 3x $item0 (+ $winAmount punten) 🎉";
      } else if (item0 == item1 || item1 == item2 || item0 == item2) {
        int winAmount = _currentBet * 2;
        _score += winAmount;
        String duplicateItem = (item0 == item1 || item0 == item2) ? item0 : item1;
        _resultMessage = "😃 Mooi zo! 2x $duplicateItem! (+ $winAmount punten)";
      } else {
        _resultMessage = "❌ Helaas! Probeer het nog eens.";
      }

      // Check of de speler onder de laagste inzet zakt
      if (_score < _betOptions[0]) {
        _resultMessage = "😭 Je punten zijn helemaal op! Klik op RESET.";
      } else if (_score < _currentBet) {
        // Schakel automatisch terug naar een lagere beschikbare inzet
        _currentBet = _betOptions.firstWhere((bet) => bet <= _score, orElse: () => _betOptions[0]);
        _resultMessage = "Inzet automatisch verlaagd naar $_currentBet.";
      }
    });
  }

  void _resetGame() {
    setState(() {
      _score = 200;
      _currentBet = 10;
      _resultMessage = "Kies je inzet en spin!";
      _isSpinning = false;
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎰 SlotMachine', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/casino.png'), // Jouw casino plaatje
            fit: BoxFit.cover, // Zorgt dat de afbeelding het hele scherm vult
            //colorFilter: ColorFilter.mode(
            //Colors.black45, // 45% zwart filter over de foto
            //BlendMode.darken,
            //),
          ),
        ),
        child: Container(
          color: Colors.black.withValues(alpha: 0.4),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 15),
                  // Score & Inzet Display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.amber, width: 1.5),
                        ),
                        child: Text(
                          '💰 Saldo: $_score',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue, width: 1.5),
                        ),
                        child: Text(
                          '🔥 Inzet: $_currentBet',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Bericht balk
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      _resultMessage,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // De 3 Wielen behuizing met winlijn
                  Container(
                    height: 160,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber, width: 4),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(3, (wheelIndex) {
                              return Expanded(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.grey),
                                  ),
                                  child: ListWheelScrollView.useDelegate(
                                    controller: _controllers[wheelIndex],
                                    itemExtent: 70,
                                    physics: const NeverScrollableScrollPhysics(),
                                    childDelegate: ListWheelChildLoopingListDelegate(
                                      children: _emojis.map((emoji) {
                                        return Center(
                                          child: Text(emoji, style: const TextStyle(fontSize: 45)),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),

                        // Winlijn
                        IgnorePointer(
                          child: Container(
                            height: 2,
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.6),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withValues(alpha: 0.8),
                                  blurRadius: 6,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 🎛️ DE 3 INZET BUTTONS
                  const Text("Kies je inzet:", style: TextStyle(fontSize: 14, color: Colors.white)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _betOptions.map((betValue) {
                      bool isSelected = _currentBet == betValue;
                      bool canAfford = _score >= betValue;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: ElevatedButton(
                          onPressed: _isSpinning || !canAfford
                              ? null
                              : () {
                                  setState(() {
                                    _currentBet = betValue;
                                  });
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSelected ? Colors.blue : Colors.grey,
                            foregroundColor: isSelected
                                ? Colors.white
                                : (canAfford ? Colors.white : Colors.white24),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isSelected ? Colors.white : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                          ),
                          child: Text(
                            '$betValue',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  // De Hoofdknop (Spin of Reset)
                  _score < _betOptions[0] && !_isSpinning
                      ? ElevatedButton(
                          onPressed: _resetGame,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                            textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          child: const Text('Reset Game'),
                        )
                      : ElevatedButton(
                          onPressed: _isSpinning ? null : _spin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 12),
                            textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: Text(_isSpinning ? 'Wachten...' : 'Spin'),
                        ),
                  const SizedBox(height: 20),
                  // Prijzentabel titel
                  const Text(
                    "📊 Prijzentabel (Jackpot = Vermenigvuldiger x Inzet)",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Prijzentabel Grid
                  SizedBox(
                    height: 140,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _emojis.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 1.3,
                        ),
                        itemBuilder: (context, index) {
                          String emoji = _emojis[index];
                          int multiplier = _baseJackpotValues[emoji] ?? 0;
                          return Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(emoji, style: const TextStyle(fontSize: 20)),
                                Text(
                                  'x$multiplier',
                                  style: const TextStyle(fontSize: 12, color: Colors.white),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
