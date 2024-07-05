import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart' as intl;

import 'constants.dart' as constants;
import 'splash_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AutoLog',
      theme: ThemeData(
        fontFamily: 'Monaco',
        scaffoldBackgroundColor: constants.slategray,
        primarySwatch: Colors.blue,
      ),
      home: SplashScreen(),
    );
  }
}

// ignore: must_be_immutable
class CarUI extends StatefulWidget {
  int userId;
  String firstName;
  String lastName;

  CarUI(
      {required this.userId, required this.firstName, required this.lastName});

  @override
  _CarUIState createState() => _CarUIState();
}

class _CarUIState extends State<CarUI> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _cars = [];
  String _errorMessage = '';
  final TextEditingController _makeController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _odometerController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();

  Future<void> _searchCars(String search) async {
    final response = await http.post(
      Uri.parse('https://autolog-b358aa95bace.herokuapp.com/api/searchcars'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'userId': widget.userId,
        'search': search,
      }),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      if (responseBody['error'] != '') {
        setState(() {
          _errorMessage = responseBody['error'];
        });
      } else {
        setState(() {
          _cars = responseBody['results'];
          _errorMessage = '';
        });
      }
    } else {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    }
  }

  Future<void> _addCar() async {
    final make = _makeController.text;
    final model = _modelController.text;
    final year = _yearController.text;
    final odometer = _odometerController.text;
    final color = _colorController.text;

    final response = await http.post(
      Uri.parse('https://autolog-b358aa95bace.herokuapp.com/api/addcar'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'userId': widget.userId,
        'make': make,
        'model': model,
        'year': year,
        'odometer': odometer,
        'color': color,
      }),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      if (responseBody['error'] != '') {
        setState(() {
          _errorMessage = responseBody['error'];
        });
      } else {
        // Car added successfully, reset form and reload cars list
        setState(() {
          _errorMessage = '';
          _makeController.clear();
          _modelController.clear();
          _yearController.clear();
          _odometerController.clear();
          _colorController.clear();
        });
        _searchCars(''); // Refresh cars list
        Navigator.of(context).pop(); // Close the popup
      }
    } else {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    }
  }

  Future<void> _deleteCar(int carId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this vehicle?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () async {
                Navigator.of(context).pop();
                final response = await http.post(
                  Uri.parse(
                      'https://autolog-b358aa95bace.herokuapp.com/api/deletecar'),
                  headers: <String, String>{
                    'Content-Type': 'application/json; charset=UTF-8',
                  },
                  body: jsonEncode(<String, dynamic>{
                    'userId': widget.userId,
                    'carId': carId,
                  }),
                );

                if (response.statusCode == 200) {
                  final responseBody = jsonDecode(response.body);
                  if (responseBody['error'] != '') {
                    setState(() {
                      _errorMessage = responseBody['error'];
                    });
                  } else {
                    // Car deleted successfully, refresh cars list
                    _searchCars('');
                  }
                } else {
                  setState(() {
                    _errorMessage = 'An error occurred. Please try again.';
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToCarInfo(int carId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CarInfo(userId: widget.userId, carId: carId),
      ),
    );
    _searchCars(''); // Refresh cars list after returning from CarInfo
  }

  Future<void> _changeName(String newFirstName, String newLastName) async {
    final response = await http.post(
      Uri.parse('https://autolog-b358aa95bace.herokuapp.com/api/changename'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'userId': widget.userId,
        'firstName': newFirstName,
        'lastName': newLastName,
      }),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      if (responseBody['error'] != '') {
        setState(() {
          _errorMessage = responseBody['error'];
        });
      } else {
        setState(() {
          // Update the local state with new names
          widget.firstName = newFirstName;
          widget.lastName = newLastName;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Name updated successfully.'),
          duration: Duration(seconds: 2),
        ));
      }
    } else {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    }
  }

  void _showNameChangeDialog() {
    final TextEditingController _firstNameController =
        TextEditingController(text: widget.firstName);
    final TextEditingController _lastNameController =
        TextEditingController(text: widget.lastName);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Name'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
              ),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Confirm'),
              onPressed: () {
                _changeName(
                    _firstNameController.text, _lastNameController.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showAddCarDialog() {
    _makeController.clear();
    _modelController.clear();
    _yearController.clear();
    _odometerController.clear();
    _colorController.clear();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Vehicle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _makeController,
                decoration: const InputDecoration(labelText: 'Make'),
              ),
              TextFormField(
                controller: _modelController,
                decoration: const InputDecoration(labelText: 'Model'),
              ),
              TextFormField(
                controller: _yearController,
                decoration: const InputDecoration(labelText: 'Year'),
              ),
              TextFormField(
                controller: _odometerController,
                decoration: const InputDecoration(labelText: 'Odometer'),
              ),
              TextFormField(
                controller: _colorController,
                decoration: const InputDecoration(labelText: 'Color'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add Vehicle'),
              onPressed: () {
                _addCar();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _searchCars('');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
                'Welcome, ${widget.firstName} ${widget.lastName} to your garage!'),
            const SizedBox(width: 10),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                _showNameChangeDialog();
              },
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Perform logout action
              Navigator.pop(
                  context); // Navigate back to login or previous screen
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(labelText: 'Search Vehicles'),
              onChanged: (value) {
                _searchCars(value);
              },
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () {
                _showAddCarDialog();
              },
              child: const Text('Add Vehicle'),
            ),
            const SizedBox(height: 20.0),
            Expanded(
              child: _cars.isEmpty
                  ? Center(
                      child: Text(
                        _errorMessage.isNotEmpty
                            ? _errorMessage
                            : 'No vehicles found.',
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _cars.length,
                      itemBuilder: (context, index) {
                        final car = _cars[index];
                        return ListTile(
                          title: Text('${car['make']} ${car['model']}'),
                          subtitle: Text(
                              'Year: ${car['year']}, Color: ${car['color']}, Odometer: ${car['odometer']}'),
                          onTap: () {
                            _navigateToCarInfo(car['carId']);
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              _deleteCar(car['carId']);
                            },
                          ),
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

class CarInfo extends StatefulWidget {
  final int userId;
  final int carId;

  CarInfo({required this.userId, required this.carId});

  @override
  _CarInfoState createState() => _CarInfoState();
}

class _CarInfoState extends State<CarInfo> {
  Map<String, dynamic>? _carInfo;
  List<dynamic>? _carNotes;
  List<dynamic>? _filteredCarNotes;
  String _errorMessage = '';
  final TextEditingController _makeController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _odometerController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _noteTypeController = TextEditingController();
  final TextEditingController _noteMilesController = TextEditingController();
  final TextEditingController _noteTextController = TextEditingController();

  Future<void> _fetchCarInfo() async {
    final response = await http.post(
      Uri.parse('https://autolog-b358aa95bace.herokuapp.com/api/getcarinfo'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'carId': widget.carId,
      }),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      if (responseBody['error'] != '') {
        setState(() {
          _errorMessage = responseBody['error'];
        });
      } else {
        setState(() {
          _carInfo = responseBody['car'];
          _errorMessage = '';
          _makeController.text = _carInfo!['make'];
          _modelController.text = _carInfo!['model'];
          _yearController.text = _carInfo!['year'];
          _odometerController.text = _carInfo!['odometer'];
          _colorController.text = _carInfo!['color'];
        });
      }
    } else {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    }
  }

  Future<void> _fetchCarNotes() async {
    final response = await http.post(
      Uri.parse('https://autolog-b358aa95bace.herokuapp.com/api/getcarnotes'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'carId': widget.carId,
      }),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      if (responseBody['error'] != '') {
        setState(() {
          _errorMessage = responseBody['error'];
        });
      } else {
        List<dynamic> notes = responseBody['notes'];
        // Sort notes by dateCreated in descending order
        notes.sort((a, b) => DateTime.parse(b['dateCreated'])
            .compareTo(DateTime.parse(a['dateCreated'])));

        setState(() {
          _carNotes = notes;
          _filteredCarNotes = _carNotes;
          _errorMessage = '';
        });
      }
    } else {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    }
  }

  Future<void> _updateCarInfo(Map<String, dynamic> updatedInfo) async {
    final response = await http.post(
      Uri.parse('https://autolog-b358aa95bace.herokuapp.com/api/updatecar'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'carId': widget.carId,
        'make': updatedInfo['make'],
        'model': updatedInfo['model'],
        'year': updatedInfo['year'],
        'odometer': updatedInfo['odometer'],
        'color': updatedInfo['color'],
      }),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      if (responseBody['error'] != '') {
        setState(() {
          _errorMessage = responseBody['error'];
        });
      } else {
        setState(() {
          _errorMessage = '';

          _fetchCarInfo(); // Refresh car info
          _fetchCarNotes(); // Refresh car notes
        });
      }
    } else {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    }
  }

  Future<void> _addNewNote() async {
    final response = await http.post(
      Uri.parse('https://autolog-b358aa95bace.herokuapp.com/api/addnote'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'carId': widget.carId,
        'note': _noteTextController.text,
        'type': _noteTypeController.text,
        'miles': _noteMilesController.text,
        'dateCreated': DateTime.now().toIso8601String(),
      }),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      if (responseBody['error'] != '') {
        setState(() {
          _errorMessage = responseBody['error'];
        });
      } else {
        setState(() {
          _errorMessage = '';
          _noteTypeController.clear();
          _noteMilesController.clear();
          _noteTextController.clear();
          _fetchCarNotes(); // Refresh car notes
        });
      }
    } else {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    }
  }

  Future<void> _deleteNote(int noteId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Note'),
          content: const Text('Are you sure you want to delete this note?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                final response = await http.post(
                  Uri.parse(
                      'https://autolog-b358aa95bace.herokuapp.com/api/deletenote'),
                  headers: <String, String>{
                    'Content-Type': 'application/json; charset=UTF-8',
                  },
                  body: jsonEncode(<String, dynamic>{
                    'carId': widget.carId,
                    'noteId': noteId,
                  }),
                );

                if (response.statusCode == 200) {
                  final responseBody = jsonDecode(response.body);
                  if (responseBody['error'] != '') {
                    setState(() {
                      _errorMessage = responseBody['error'];
                    });
                  } else {
                    setState(() {
                      _errorMessage = '';
                      _fetchCarNotes(); // Refresh car notes after deletion
                    });
                  }
                } else {
                  setState(() {
                    _errorMessage = 'An error occurred. Please try again.';
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateNote(
      int noteId, String type, String miles, String note) async {
    final response = await http.post(
      Uri.parse('https://autolog-b358aa95bace.herokuapp.com/api/updatenote'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'carId': widget.carId,
        'noteId': noteId,
        'type': type,
        'miles': miles,
        'note': note,
        'dateCreated': DateTime.now().toIso8601String(),
      }),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      if (responseBody['error'] != '') {
        setState(() {
          _errorMessage = responseBody['error'];
        });
      } else {
        setState(() {
          _errorMessage = '';
          _fetchCarNotes(); // Refresh car notes
        });
      }
    } else {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    }
  }

  void _showEditCarDialog() {
    // Create new controllers for the edit dialog
    final TextEditingController makeController =
        TextEditingController(text: _makeController.text);
    final TextEditingController modelController =
        TextEditingController(text: _modelController.text);
    final TextEditingController yearController =
        TextEditingController(text: _yearController.text);
    final TextEditingController odometerController =
        TextEditingController(text: _odometerController.text);
    final TextEditingController colorController =
        TextEditingController(text: _colorController.text);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Car Information'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: makeController,
                decoration: const InputDecoration(labelText: 'Make'),
              ),
              TextField(
                controller: modelController,
                decoration: const InputDecoration(labelText: 'Model'),
              ),
              TextField(
                controller: yearController,
                decoration: const InputDecoration(labelText: 'Year'),
              ),
              TextField(
                controller: odometerController,
                decoration: const InputDecoration(labelText: 'Odometer'),
              ),
              TextField(
                controller: colorController,
                decoration: const InputDecoration(labelText: 'Color'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                // Create a map with the updated values
                Map<String, dynamic> updatedInfo = {
                  'make': makeController.text,
                  'model': modelController.text,
                  'year': yearController.text,
                  'odometer': odometerController.text,
                  'color': colorController.text,
                };

                // Call _updateCarInfo with the updated values
                _updateCarInfo(updatedInfo);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showAddNoteDialog() {
    _noteTypeController.clear();
    _noteMilesController.clear();
    _noteTextController.clear();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Note'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: _noteTypeController,
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              TextField(
                controller: _noteMilesController,
                decoration: const InputDecoration(labelText: 'Miles'),
              ),
              TextField(
                controller: _noteTextController,
                decoration: const InputDecoration(labelText: 'Note'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                Navigator.of(context).pop();
                _addNewNote();
              },
            ),
          ],
        );
      },
    );
  }

  void _filterNotes(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredCarNotes = _carNotes;
      });
    } else {
      setState(() {
        _filteredCarNotes = _carNotes!.where((note) {
          // Convert date string to DateTime object
          DateTime noteDate = DateTime.parse(note['dateCreated']);
          String monthName = intl.DateFormat.MMMM().format(noteDate);
          String day = intl.DateFormat.d().format(noteDate);
          String year = intl.DateFormat.y().format(noteDate);

          return note['note']
                  .toString()
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              note['type']
                  .toString()
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              note['miles']
                  .toString()
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              monthName.toLowerCase().contains(query.toLowerCase()) ||
              day.contains(query) || // Check for day number
              year.contains(query); // Check for year number
        }).toList();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchCarInfo();
    _fetchCarNotes();
    _searchController.addListener(() {
      _filterNotes(_searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Information'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _carInfo == null
            ? Center(
                child: Text(
                  _errorMessage.isNotEmpty ? _errorMessage : 'Loading...',
                  style: const TextStyle(color: Colors.red),
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Make: ${_carInfo!['make']}',
                          style: const TextStyle(
                              fontSize: 18.0, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10.0),
                        Text(
                          'Model: ${_carInfo!['model']}',
                          style: const TextStyle(fontSize: 18.0),
                        ),
                        const SizedBox(height: 10.0),
                        Text(
                          'Year: ${_carInfo!['year']}',
                          style: const TextStyle(fontSize: 18.0),
                        ),
                        const SizedBox(height: 10.0),
                        Text(
                          'Color: ${_carInfo!['color']}',
                          style: const TextStyle(fontSize: 18.0),
                        ),
                        const SizedBox(height: 10.0),
                        Text(
                          'Odometer: ${_carInfo!['odometer']}',
                          style: const TextStyle(fontSize: 18.0),
                        ),
                        const SizedBox(height: 20.0),
                        ElevatedButton(
                          onPressed: () {
                            _showEditCarDialog();
                          },
                          child: const Text('Edit'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20.0),
                    ElevatedButton(
                      onPressed: _showAddNoteDialog,
                      child: const Text('Add Note'),
                    ),
                    const SizedBox(height: 20.0),
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: 'Search Notes',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    _filteredCarNotes == null
                        ? Center(
                            child: Text(
                              _errorMessage.isNotEmpty
                                  ? _errorMessage
                                  : 'Loading notes...',
                              style: const TextStyle(color: Colors.red),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _filteredCarNotes!.map((note) {
                              final noteId = note['noteId'];

                              // Format the dateCreated field
                              final createdDate =
                                  DateTime.parse(note['dateCreated']);
                              final formattedDate =
                                  '${intl.DateFormat.yMMMMd().format(createdDate)}';

                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Service Type: ${note['type']}',
                                                style: const TextStyle(
                                                    fontSize: 16.0,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              Text(
                                                'Miles: ${note['miles']}',
                                                style: const TextStyle(
                                                    fontSize: 16.0),
                                              ),
                                              Text(
                                                'Note: ${note['note']}',
                                                style: const TextStyle(
                                                    fontSize: 16.0),
                                              ),
                                              Text(
                                                'Created At: $formattedDate',
                                                style: const TextStyle(
                                                    fontSize: 14.0,
                                                    color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () {
                                            // Create new controllers for the edit dialog
                                            final TextEditingController
                                                typeController =
                                                TextEditingController(
                                                    text: note['type']);
                                            final TextEditingController
                                                milesController =
                                                TextEditingController(
                                                    text: note['miles']);
                                            final TextEditingController
                                                noteController =
                                                TextEditingController(
                                                    text: note['note']);

                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title:
                                                      const Text('Edit Note'),
                                                  content: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      TextField(
                                                        controller:
                                                            typeController,
                                                        decoration:
                                                            const InputDecoration(
                                                                labelText:
                                                                    'Service Type'),
                                                      ),
                                                      TextField(
                                                        controller:
                                                            milesController,
                                                        decoration:
                                                            const InputDecoration(
                                                                labelText:
                                                                    'Miles'),
                                                      ),
                                                      TextField(
                                                        controller:
                                                            noteController,
                                                        decoration:
                                                            const InputDecoration(
                                                                labelText:
                                                                    'Note'),
                                                      ),
                                                    ],
                                                  ),
                                                  actions: <Widget>[
                                                    TextButton(
                                                      child:
                                                          const Text('Cancel'),
                                                      onPressed: () {
                                                        // Clear text in controllers when cancel is pressed
                                                        typeController.clear();
                                                        milesController.clear();
                                                        noteController.clear();
                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                    ),
                                                    TextButton(
                                                      child: const Text('Save'),
                                                      onPressed: () {
                                                        _updateNote(
                                                            noteId,
                                                            typeController.text,
                                                            milesController
                                                                .text,
                                                            noteController
                                                                .text);
                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          onPressed: () =>
                                              _deleteNote(note['noteId']),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                  ],
                ),
              ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();
  String _errorMessage = '';
  bool _passwordsMatch = false;
  bool _showPasswordRequirements = false;
  bool _isPasswordValid = false;

  void _checkPasswordsMatch() {
    setState(() {
      _passwordsMatch =
          _confirmPasswordController.text == _passwordController.text;
    });
  }

  void _validatePassword(String value) {
    setState(() {
      _isPasswordValid = _isPasswordCompliant(value);
    });
  }

  bool _isPasswordCompliant(String password) {
    if (password.isEmpty) {
      return false;
    }

    final passwordRegExp =
        RegExp(r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$');
    return passwordRegExp.hasMatch(password);
  }

  Future<void> _register() async {
    final firstName = _firstNameController.text;
    final lastName = _lastNameController.text;
    final email = _emailController.text;
    final password = _passwordController.text;

    final response = await http.post(
      Uri.parse('https://autolog-b358aa95bace.herokuapp.com/api/register'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      if (responseBody.containsKey('error')) {
        setState(() {
          _errorMessage = responseBody['error'];
        });
      } else if (responseBody.containsKey('message')) {
        setState(() {
          _errorMessage = responseBody['message'];
        });
      } else {
        setState(() {
          _errorMessage = 'An unexpected error occurred.';
        });
      }
    } else {
      setState(() {
        _errorMessage =
            'An error occurred. User may already exist. Please try again.';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _passwordFocusNode.addListener(() {
      setState(() {
        _showPasswordRequirements = _passwordFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _passwordFocusNode.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your first name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your last name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  // Basic email validation
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: _buildPasswordRequirementsIcon(_isPasswordValid),
                ),
                obscureText: true,
                focusNode: _passwordFocusNode,
                onChanged: (value) {
                  _validatePassword(value);
                  _checkPasswordsMatch(); // Update passwords match status
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (!_isPasswordValid) {
                    return 'Password must be 8-20 characters, with at least one uppercase, lowercase, number, and symbol.';
                  }
                  return null;
                },
              ),
              Visibility(
                visible: _showPasswordRequirements,
                child: const Text(
                  "Password must be 8-20 characters, with at least one uppercase, lowercase, number, and symbol.",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  suffixIcon: _passwordsMatch
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.cancel, color: Colors.red),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
                onChanged: (value) {
                  _checkPasswordsMatch(); // Update passwords match status
                },
              ),
              const SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _register();
                  }
                },
                child: const Text('Register'),
              ),
              const SizedBox(height: 20.0),
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordRequirementsIcon(bool isRequirementMet) {
    return isRequirementMet
        ? const Icon(Icons.check_circle, color: Colors.green)
        : const Icon(Icons.cancel, color: Colors.red);
  }
}
