import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UpdatePrestationPage extends StatefulWidget {
  final Map<String, dynamic> prestation;

  UpdatePrestationPage({required this.prestation});

  @override
  _UpdatePrestationPageState createState() => _UpdatePrestationPageState();
}

class _UpdatePrestationPageState extends State<UpdatePrestationPage> {
  final storage = FlutterSecureStorage();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.prestation['title'];
    _priceController.text = widget.prestation['price'].toString();
    _descriptionController.text = widget.prestation['description'];
  }

  Future<void> _updatePrestation() async {
    final prestationId = widget.prestation['_id'];
    final url =
        Uri.parse('http://10.0.2.2:8080/api/v1/prestation/$prestationId');
    final accessToken = await storage.read(key: 'accessToken');

    if (accessToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Access Token not found.')),
      );
      return;
    }

    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "garage": widget.prestation['garage'], // Garder le même garageId
        "title": _titleController.text,
        "price": int.parse(_priceController.text),
        "description": _descriptionController.text,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Prestation updated successfully')),
      );
      Navigator.pop(context, true); // Retour à la liste après mise à jour
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update prestation')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Update Prestation'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: 'Price',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: _updatePrestation,
              child: Text('Update Prestation'),
            ),
          ],
        ),
      ),
    );
  }
}
