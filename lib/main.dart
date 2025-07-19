import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/travel_time_entry.dart';
import 'models/location.dart';
import 'services/migration_service.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();
  
  // Register adapters
  Hive.registerAdapter(TravelTimeEntryAdapter());
  Hive.registerAdapter(LocationAdapter());
  
  // Open boxes
  await Hive.openBox<TravelTimeEntry>(AppConstants.travelEntriesBox);
  await Hive.openBox<Location>(AppConstants.locationsBox);
  
  // Run migration if needed
  await MigrationService.migrateIfNeeded();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travel Time Logger',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: TravelTimeLoggerPage(),
    );
  }
}

@HiveType(typeId: 0)
class TravelTimeEntry {
  @HiveField(0)
  final DateTime date;
  @HiveField(1)
  final String departure;
  @HiveField(2)
  final String arrival;
  @HiveField(3)
  final String? info;
  @HiveField(4)
  final int minutes;

  TravelTimeEntry({
    required this.date,
    required this.departure,
    required this.arrival,
    this.info,
    required this.minutes,
  });
}

class TravelTimeEntryAdapter extends TypeAdapter<TravelTimeEntry> {
  @override
  final int typeId = 0;

  @override
  TravelTimeEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TravelTimeEntry(
      date: fields[0] as DateTime,
      departure: fields[1] as String,
      arrival: fields[2] as String,
      info: fields[3] as String?,
      minutes: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, TravelTimeEntry obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.departure)
      ..writeByte(2)
      ..write(obj.arrival)
      ..writeByte(3)
      ..write(obj.info)
      ..writeByte(4)
      ..write(obj.minutes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TravelTimeEntryAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}


class TravelTimeLoggerPage extends StatefulWidget {
  const TravelTimeLoggerPage({super.key});

  @override
  _TravelTimeLoggerPageState createState() => _TravelTimeLoggerPageState();
}

class _TravelTimeLoggerPageState extends State<TravelTimeLoggerPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _departureController = TextEditingController();
  final TextEditingController _arrivalController = TextEditingController();
  final TextEditingController _infoController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  late Box<TravelTimeEntry> _travelEntriesBox;

  @override
  void initState() {
    super.initState();
    _travelEntriesBox = Hive.box<TravelTimeEntry>('travelEntriesBox');
  }

  @override
  void dispose() {
    _dateController.dispose();
    _departureController.dispose();
    _arrivalController.dispose();
    _infoController.dispose();
    _timeController.dispose();
    _travelEntriesBox.close();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _logTravelTime() {
    if (_formKey.currentState!.validate()) {
      final entry = TravelTimeEntry(
        date: DateTime.parse(_dateController.text),
        departure: _departureController.text,
        arrival: _arrivalController.text,
        info: _infoController.text.isEmpty ? null : _infoController.text,
        minutes: int.parse(_timeController.text),
      );

      _travelEntriesBox.add(entry);

      // Clear the form
      _formKey.currentState!.reset();
      _dateController.clear();
      _departureController.clear();
      _arrivalController.clear();
      _infoController.clear();
      _timeController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Travel time logged!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Time Logger'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  TextFormField(
                    controller: _dateController,
                    readOnly: true,
                    onTap: () => _selectDate(context),
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      hintText: 'Select Date',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a date';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _departureController,
                    decoration: const InputDecoration(
                      labelText: 'From (address/city)',
                      hintText: 'e.g., HEMFRID, FABRIKSGATAN 13, 412 50 GÖTEBORG',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter departure location';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _arrivalController,
                    decoration: const InputDecoration(
                      labelText: 'To (address/city)',
                      hintText: 'e.g., TRANSISTORGATAN 36, 42135, VÄSTRA FRÖLUNDA',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter arrival location';
                      }
                      return null;
                    },
                  ),
                   TextFormField(
                    controller: _infoController,
                    decoration: const InputDecoration(
                      labelText: 'Other Information (ex. förseringar som bidragit)',
                      hintText: 'Optional information',
                    ),
                  ),
                  TextFormField(
                    controller: _timeController,
                    decoration: const InputDecoration(
                      labelText: 'Minutes Spent',
                      hintText: 'e.g., 51',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter time spent';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _logTravelTime,
                    child: const Text('Log Travel Time'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: _travelEntriesBox.listenable(),
                builder: (context, Box<TravelTimeEntry> box, _) {
                  if (box.values.isEmpty) {
                    return Center(child: Text('No travel entries yet.'));
                  }
                  return ListView.builder(
                    itemCount: box.values.length,
                    itemBuilder: (context, index) {
                      final entry = box.getAt(index)!; // Get entry from box
                      return ListTile(
                        title: Text('Date: ${DateFormat('yyyy-MM-dd').format(entry.date)}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('From: ${entry.departure}'),
                            Text('To: ${entry.arrival}'),
                            if (entry.info != null && entry.info!.isNotEmpty) Text('Info: ${entry.info}'),
                            Text('Minutes: ${entry.minutes}'),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
