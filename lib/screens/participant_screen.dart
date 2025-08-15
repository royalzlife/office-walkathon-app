import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:provider/provider.dart';
import 'package:myapp/services/firebase_service.dart';
import 'package:myapp/services/sheets_service.dart';

class ParticipantScreen extends StatefulWidget {
  final String name;
  const ParticipantScreen({Key? key, required this.name}) : super(key: key);

  @override
  _ParticipantScreenState createState() => _ParticipantScreenState();
}

class _ParticipantScreenState extends State<ParticipantScreen> {
  late StreamSubscription<StepCount> _stepCountSubscription;
  late StreamSubscription _competitionStateSubscription;
  final SheetsService _sheetsService = SheetsService();

  int _initialSteps = 0;
  int _currentSteps = 0;
  String _competitionStatus = 'Waiting for admin...';
  Timer? _timer;
  int _countdown = 25 * 60; // 25 minutes in seconds

  @override
  void initState() {
    super.initState();
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);
    _listenForCompetitionState(firebaseService);
  }

  void _listenForCompetitionState(FirebaseService firebaseService) {
    _competitionStateSubscription =
        firebaseService.getCompetitionState().listen((state) {
      if (mounted) {
        if (state['status'] == 'in_progress' && _competitionStatus != 'In Progress') {
          setState(() {
            _competitionStatus = 'In Progress';
          });
          _startCompetition();
        } else if (state['status'] == 'finished') {
          _stopCompetition();
        }
      }
    });
  }

  void _startCompetition() async {
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);
    await firebaseService.addParticipant(widget.name);
    _startTimer();
    _startStepCounting();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        if (mounted) {
          setState(() {
            _countdown--;
          });
        }
      } else {
        _stopCompetition();
      }
    });
  }

  void _startStepCounting() {
    _stepCountSubscription = Pedometer.stepCountStream.listen(
      (StepCount event) {
        if (mounted) {
          setState(() {
            if (_initialSteps == 0) {
              _initialSteps = event.steps;
            }
            _currentSteps = event.steps - _initialSteps;
          });
          final firebaseService = Provider.of<FirebaseService>(context, listen: false);
          firebaseService.updateStepCount(widget.name, _currentSteps);
        }
      },
      onError: (error) {
        print("Pedometer Error: $error");
      },
    );
  }

  void _stopCompetition() {
    _timer?.cancel();
    if (mounted) {
      if (_competitionStatus != 'Finished!') {
        _stepCountSubscription.cancel();
        _sheetsService.uploadToSheet(widget.name, _currentSteps);
        setState(() {
          _competitionStatus = 'Finished!';
        });
      }
    }
  }

  String get _timerText {
    final minutes = (_countdown ~/ 60).toString().padLeft(2, '0');
    final seconds = (_countdown % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (mounted) {
       _stepCountSubscription.cancel();
       _competitionStateSubscription.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Participant: ${widget.name}'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_competitionStatus, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 20),
            if (_competitionStatus == 'In Progress')
              Text(
                _timerText,
                style: Theme.of(context).textTheme.displaySmall,
              ),
            const SizedBox(height: 40),
            Text(
              '$_currentSteps',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const Text('Steps'),
          ],
        ),
      ),
    );
  }
}