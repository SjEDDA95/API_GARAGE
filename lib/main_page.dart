import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:test_for_api/prestation_details_page.dart';
import 'package:test_for_api/prestations_list_page.dart';
import 'login_page.dart';
import 'package:http/http.dart' as http;

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final storage = FlutterSecureStorage();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkAndRefreshToken();
  }

  Future<void> _createPrestation() async {
    // Récupérer le garageId et l'accessToken depuis flutter_secure_storage
    final garageId = await storage.read(key: 'garageId');
    final accessToken = await storage.read(key: 'accessToken');

    print('Garage ID: $garageId');
    print('Access Token: $accessToken');

    if (garageId == null || accessToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Garage ID or Access Token not found.')),
      );
      return;
    }

    final url = Uri.parse('http://10.0.2.2:8080/api/v1/prestation');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken', // Utilisation du Bearer Token
      },
      body: jsonEncode({
        "garage": garageId,
        "title": _titleController.text,
        "price": int.parse(_priceController.text),
        "description": _descriptionController.text,
      }),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Prestation created successfully.')),
      );

      // Extraction des informations de la prestation pour les passer à la nouvelle page
      final prestationData = jsonDecode(response.body);
      String title = prestationData['title'];
      int price = prestationData['price'];
      String description = prestationData['description'];

      // Redirection vers PrestationDetailsPage en passant les informations
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PrestationsListPage(garageId: garageId!),
        ),
      );

      _titleController.clear();
      _priceController.clear();
      _descriptionController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create prestation.')),
      );
    }
  }

  Future<void> _checkAndRefreshToken() async {
    final accessToken = await storage.read(key: 'accessToken');
    final tokenObtainedAt = await storage.read(key: 'tokenObtainedAt');

    if (accessToken != null && tokenObtainedAt != null) {
      final tokenTime = DateTime.parse(tokenObtainedAt);
      final currentTime = DateTime.now();
      final tokenDuration = currentTime.difference(tokenTime).inSeconds;

      if (tokenDuration > 3600) {
        // Assumer que le token est valide pour 1 heure
        await _refreshToken(accessToken);
      } else {
        print('Token is still valid');
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }

  Future<void> _refreshToken(String expiredToken) async {
    final url = Uri.parse('http://10.0.2.2:8080/api/v1/refresh');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "accessToken": expiredToken,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final newAccessToken = responseData['accessToken'];

      await storage.write(key: 'accessToken', value: newAccessToken);
      await storage.write(
          key: 'tokenObtainedAt', value: DateTime.now().toIso8601String());

      print('Token refreshed successfully');
    } else {
      print('Failed to refresh token');
      await _logout();
    }
  }

  Future<void> _logout() async {
    // Supprimer toutes les données sensibles du stockage sécurisé
    await storage.delete(key: 'accessToken');
    await storage.delete(key: 'tokenObtainedAt');

    // Rediriger vers la page de login
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Main Page'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await storage.delete(key: 'accessToken');
              await storage.delete(key: 'tokenObtainedAt');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
              onPressed: _createPrestation,
              child: Text('Create Prestation'),
            ),
          ],
        ),
      ),
    );
  }
}
