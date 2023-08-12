import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'Last_modal_dialog.dart';
import 'constants.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_maps_webservice/places.dart';

const kGoogleApiKey = "AIzaSyC6NOrIEtD-n4-KT9RrYErC2E_fPysR6SA"; // Замените на свой ключ API
GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: kGoogleApiKey);

class ConfirmEventDialog extends StatefulWidget {
  final VoidCallback onDialogClosed;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String notes;

  const ConfirmEventDialog({
    Key? key,
    required this.onDialogClosed,
    required this.startDateTime,
    required this.endDateTime,
    required this.notes,
  }) : super(key: key);

  @override
  _ConfirmEventDialogState createState() => _ConfirmEventDialogState();
}




class _ConfirmEventDialogState extends State<ConfirmEventDialog> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _aptController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();
  List<dynamic>? _foundContacts;
  int? _selectedContactId;

  @override
  void initState() {
    super.initState();

    _nameController.addListener(() {
      if (_nameController.text.length >= 3) {
        _searchContactsByName(_nameController.text);
      }
    });

    _phoneController.addListener(() {
      if (_phoneController.text.length >= 5) {
        _searchContactsByPhone(_phoneController.text);
      }
    });
  }

  Future<void> _searchContactsByName(String name) async {
    final response = await http.get(
      Uri.parse(
          '$baseUrl/api.php?action=searchContactsByName&name=$name'),
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      setState(() {
        _foundContacts = jsonResponse;
      });
    } else {
      throw Exception('Failed to load contacts');
    }
  }

  Future<void> _searchContactsByPhone(String phone) async {
    final response = await http.get(
      Uri.parse(
          '$baseUrl/api.php?action=searchContactsByPhone&phone=$phone'),
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      setState(() {
        _foundContacts = jsonResponse;
      });
    } else {
      throw Exception('Failed to load contacts');
    }
  }

  void _showContactsDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Found Contacts'),
            content: SingleChildScrollView(
              child: Column(
                children: _foundContacts!.map((contact) {
                  return Card(
                    child: ListTile(
                      title: Text(contact['name']),
                      subtitle: Text(
                          '${contact['phone1']}\n${contact['address']}, ${contact['city']}, ${contact['zipcode']}'
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            _selectedContactId = contact['id'];
                          });
                          int count = 0;
                          Navigator.of(context).popUntil((route) =>
                          count++ == 2);
                          // close the current dialog

                          // Open the LastModalDialog
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return LastModalDialog(
                                onDialogClosed: widget.onDialogClosed,
                                startDateTime: widget.startDateTime,
                                endDateTime: widget.endDateTime,
                                notes: widget.notes,
                                selectedContactId: _selectedContactId ??
                                    0, // Here you could provide a default value
                              );
                            },
                          );
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        }
    );
  }
  Future<Iterable<Map<String, dynamic>>> fetchPlaces(String input) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api.php?action=searchPlaces&input=$input'),
    );
    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = json.decode(response.body);
      return List<Map<String, dynamic>>.from(jsonResponse['predictions']);
      // assuming predictions contains a list of places
    } else {
      throw Exception('Failed to load suggestions');
    }
  }





  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFCCD6E0),


      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(32.0))),
      contentPadding: const EdgeInsets.only(top: 10.0),
      title: const Text('Contact Information'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'Enter name'),
            ),

            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(hintText: 'Enter phone'),
            ),
            if (_foundContacts != null && _foundContacts!.isNotEmpty)
              TextButton(
                onPressed: () => _showContactsDialog(context),
                child: Text('Found ${_foundContacts!.length} contacts.'),
              ),

            Autocomplete<Map<String, dynamic>>(

              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.length < 3) {
                  return const Iterable<Map<String, dynamic>>.empty();
                } else {
                  return fetchPlaces(textEditingValue.text);
                }
              },
              displayStringForOption: (Map<String, dynamic> option) => option['description'] ?? '',
              onSelected: (Map<String, dynamic> suggestion) async {
                _addressController.text = suggestion['description'] ?? '';

                // Запрашиваем детали места
                var response = await http.get(
                  Uri.parse('$baseUrl/api.php?action=fetchPlaceDetails&placeId=${suggestion['place_id']}'),
                );
                if (response.statusCode == 200) {
                  Map<String, dynamic> jsonResponse = json.decode(response.body);
                  var address = jsonResponse['formatted_address'];
                  List<dynamic> addressComponents = jsonResponse['address_components'];

                  Map<String, String> addressParts = {};
                  for (var component in addressComponents) {
                    String type = component['types'][0];
                    addressParts[type] = component['long_name'];
                  }

                  _streetController.text = '${addressParts["street_number"]} ${addressParts["route"]}';
                  _addressController.text = address;
                  _cityController.text = addressParts['locality']!;
                  _stateController.text = addressParts['administrative_area_level_1']!;
                  _zipController.text = addressParts['postal_code']!;
                }
              },
              optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<Map<String, dynamic>> onSelected, Iterable<Map<String, dynamic>> options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4.0,
                    child: SizedBox(
                      height: 300.0,
                      width: 240.0,// Change as per your requirement
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: options.length,
                        itemBuilder: (BuildContext context, int index) {

                          final Map<String, dynamic> option = options.elementAt(index);
                          return GestureDetector(
                            onTap: () {
                              onSelected(option);
                            },
                            child: ListTile(
                              title: Expanded(
                                child: Text(option['description'] ?? ''),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
    fieldViewBuilder: (BuildContext context, TextEditingController _addressController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
    return TextField(
    controller: _addressController,
    focusNode: focusNode,
    onSubmitted: (String value) {
    onFieldSubmitted();
    },
    decoration: const InputDecoration(hintText: 'Address auto-suggestions'),
    );
    },
            ),


            TextField(
              controller: _streetController,
              decoration: const InputDecoration(hintText: 'Address'),
            ),
            TextField(
              controller: _aptController,
              decoration: const InputDecoration(hintText: 'Apt#'),
            ),
            TextField(
              controller: _cityController,
              decoration: const InputDecoration(hintText: 'City'),
            ),
            TextField(
              controller: _stateController,
              decoration: const InputDecoration(hintText: 'State'),
            ),
            TextField(
              controller: _zipController,
              decoration: const InputDecoration(hintText: 'Zipcode'),
            ),

          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            if (_selectedContactId != null) {
              // здесь будет код для обработки выбранного контакта
            } else {
              // создаем новый контакт
              final response = await http.post(
                Uri.parse('$baseUrl/api.php?action=addContact'),
                body: {
                  'name': _nameController.text,
                  'phone1': _phoneController.text,
                  'phone1_desc': 'Mobile', // например, Mobile, Home, etc.
                  'email': '', // предположительно в вашем UI нет поля для электронной почты
                  'address': _streetController.text,
                  'apartment': _aptController.text,
                  'city': _cityController.text,
                  'state': _stateController.text,
                  'zipcode': _zipController.text,

                },
              );

              if (response.statusCode == 200) {
                final jsonResponse = json.decode(response.body);
                if (jsonResponse['success']) {
                  _selectedContactId = jsonResponse['contactId'];
                } else {
                  // обрабатываем ошибку
                  print('Error: ${jsonResponse['error']}');
                }
              } else {
                print('Error: ${response.statusCode}');
              }
            }

            // после успешного добавления контакта мы показываем LastModalDialog
            if (_selectedContactId != null) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (BuildContext context) {
                    return LastModalDialog(
                      onDialogClosed: widget.onDialogClosed,
                      startDateTime: widget.startDateTime,
                      endDateTime: widget.endDateTime,
                      notes: widget.notes,
                      selectedContactId: _selectedContactId ??
                          0,
                    );
                  },
                ),
              );
            }
          },
          child: const Text('Confirm'),
        ),
      ],

    );
  }

}
