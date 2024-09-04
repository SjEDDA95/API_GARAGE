import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _firstnameController = TextEditingController();
  final TextEditingController _lastnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _garagePhoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressNumberController =
      TextEditingController();
  final TextEditingController _addressNameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();
  final storage = FlutterSecureStorage();

  Future<void> _registerUser() async {
    final url = Uri.parse('http://10.0.2.2:8080/api/v1/mechanicsignup');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "firstname": _firstnameController.text,
        "lastname": _lastnameController.text,
        "email": _emailController.text,
        "password": _passwordController.text,
        "garagePhone": _garagePhoneController.text,
        "name": _nameController.text,
        "addressNumber": _addressNumberController.text,
        "addressName": _addressNameController.text,
        "city": _cityController.text,
        "zipCode": _zipCodeController.text,
      }),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      final accessToken = responseData['accessToken'];

      // Stocker le token de manière sécurisée
      await storage.write(key: 'accessToken', value: accessToken);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration successful')),
      );

      // Fetch garages using the access token
      await _fetchGarageId(accessToken);

      Navigator.pop(context);
    } else {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed')),
      );
    }
  }

  Future<void> _fetchGarageId(String accessToken) async {
    final url = Uri.parse('http://10.0.2.2:8080/api/v1/garages');

    final response = await http.get(
      url,
      headers: {
        'Authorization':
            'Bearer $accessToken', // Pass the access token in the header
      },
    );

    if (response.statusCode == 200) {
      // Decode the response body
      final responseData = jsonDecode(response.body);

      // Access the list of garages from the correct key
      List<dynamic> garages = responseData['garages'];

      // Log the number of garages fetched
      print('Number of garages fetched: ${garages.length}');

      // Log each garage's information for debugging
      garages.forEach((garage) {
        print(
            'Garage: ${garage['name']} - ${garage['addressName']}, ${garage['city']}');
      });

      // Find the garage by address name
      var matchingGarage = garages.firstWhere(
        (garage) =>
            garage['addressName'] == _addressNameController.text &&
            garage['city'] == _cityController.text,
        orElse: () => null,
      );

      if (matchingGarage != null) {
        String garageId = matchingGarage['_id'];
        // Store garageId in SharedPreferences
        await storage.write(key: 'garageId', value: garageId);

        // Print the garageId in the terminal
        print('Garage ID: $garageId');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Garage ID stored successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Garage not found')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch garages')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: <Widget>[
            TextField(
              controller: _firstnameController,
              decoration: InputDecoration(
                labelText: 'First Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _lastnameController,
              decoration: InputDecoration(
                labelText: 'Last Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _garagePhoneController,
              decoration: InputDecoration(
                labelText: 'Garage Phone',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Garage Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _addressNumberController,
              decoration: InputDecoration(
                labelText: 'Garage Address Number',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _addressNameController,
              decoration: InputDecoration(
                labelText: 'Garage Address Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _cityController,
              decoration: InputDecoration(
                labelText: 'Garage City',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _zipCodeController,
              decoration: InputDecoration(
                labelText: 'Garage Zip Code',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: _registerUser,
              child: Text('REGISTER'),
            ),
          ],
        ),
      ),
    );
  }
}
