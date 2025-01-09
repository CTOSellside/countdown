import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: CountdownDashboardScreen(),
    );
  }
}

class Countdown {
  String name;
  DateTime targetDate;

  Countdown({required this.name, required this.targetDate});
}

class CountdownDashboardScreen extends StatefulWidget {
  @override
  _CountdownDashboardScreenState createState() => _CountdownDashboardScreenState();
}

class _CountdownDashboardScreenState extends State<CountdownDashboardScreen> {
  List<Countdown> _countdowns = [];
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startRealtimeUpdate();
  }

  void _startRealtimeUpdate() {
    _timer = Timer.periodic(Duration(milliseconds: 100), (Timer timer) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _addCountdown(String name, DateTime targetDate) {
    setState(() {
      _countdowns.add(Countdown(name: name, targetDate: targetDate));
      _countdowns.sort((a, b) => a.targetDate.compareTo(b.targetDate));
    });
  }

  void _editCountdown(int index, DateTime newDate) {
    setState(() {
      _countdowns[index].targetDate = newDate;
      _countdowns.sort((a, b) => a.targetDate.compareTo(b.targetDate));
    });
  }

  void _navigateToAddCountdownScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddCountdownScreen()),
    );

    if (result != null && result is Countdown) {
      _addCountdown(result.name, result.targetDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dashboard de cuentas regresivas"),
      ),
      body: ListView.builder(
        itemCount: _countdowns.length,
        itemBuilder: (context, index) {
          final countdown = _countdowns[index];
          final remaining = countdown.targetDate.difference(DateTime.now());
          final remainingText = remaining.isNegative
              ? "¡Tiempo completado!"
              : "${remaining.inDays}d ${remaining.inHours % 24}h ${remaining.inMinutes % 60}m ${remaining.inSeconds % 60}s ${remaining.inMilliseconds % 1000}ms";
          return ListTile(
            title: Text(countdown.name),
            subtitle: Text("Fecha: ${countdown.targetDate.toLocal().toString()}\nTiempo restante: $remainingText"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CountdownScreen(
                    countdown: countdown,
                    onEdit: (newDate) => _editCountdown(index, newDate),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddCountdownScreen,
        child: Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: "Agregar"),
        ],
        onTap: (index) {
          if (index == 1) {
            _navigateToAddCountdownScreen();
          }
        },
      ),
    );
  }
}

class AddCountdownScreen extends StatefulWidget {
  @override
  _AddCountdownScreenState createState() => _AddCountdownScreenState();
}

class _AddCountdownScreenState extends State<AddCountdownScreen> {
  final TextEditingController _nameController = TextEditingController();
  DateTime? _selectedDate;

  void _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Agregar cuenta regresiva"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: "Nombre"),
            ),
            SizedBox(height: 16.0),
            Row(
              children: [
                Text(_selectedDate == null
                    ? "Seleccione fecha y hora"
                    : "Fecha: ${_selectedDate!.toLocal().toString()}"),
                Spacer(),
                ElevatedButton(
                  onPressed: () => _selectDateTime(context),
                  child: Text("Seleccionar"),
                ),
              ],
            ),
            Spacer(),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.isNotEmpty && _selectedDate != null) {
                  final countdown = Countdown(
                    name: _nameController.text,
                    targetDate: _selectedDate!,
                  );
                  Navigator.pop(context, countdown);
                }
              },
              child: Text("Agregar"),
            ),
          ],
        ),
      ),
    );
  }
}

class CountdownScreen extends StatefulWidget {
  final Countdown countdown;
  final Function(DateTime) onEdit;

  CountdownScreen({required this.countdown, required this.onEdit});

  @override
  _CountdownScreenState createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<CountdownScreen> {
  late Timer _timer;
  String _timeRemaining = "";

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(milliseconds: 100), (Timer timer) {
      final DateTime now = DateTime.now();
      final Duration difference = widget.countdown.targetDate.difference(now);

      if (difference.isNegative) {
        setState(() {
          _timeRemaining = "¡Tiempo completado!";
        });
        _timer.cancel();
      } else {
        setState(() {
          final int days = difference.inDays;
          final int hours = difference.inHours % 24;
          final int minutes = difference.inMinutes % 60;
          final int seconds = difference.inSeconds % 60;
          final int milliseconds = difference.inMilliseconds % 1000;

          _timeRemaining =
              "${days} días, ${hours} horas, ${minutes} minutos, ${seconds} segundos, ${milliseconds} ms.";
        });
      }
    });
  }

  void _editDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: widget.countdown.targetDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(widget.countdown.targetDate),
      );

      if (pickedTime != null) {
        final newDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        widget.onEdit(newDate);
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.countdown.name),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: _editDateTime,
          ),
        ],
      ),
      body: Center(
        child: Text(
          _timeRemaining,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
      ),
    );
  }
}
