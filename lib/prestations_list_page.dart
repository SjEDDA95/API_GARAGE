import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:test_for_api/update_prestation_page.dart';

class PrestationsListPage extends StatefulWidget {
  final String garageId;

  PrestationsListPage({required this.garageId});

  @override
  _PrestationsListPageState createState() => _PrestationsListPageState();
}

class _PrestationsListPageState extends State<PrestationsListPage> {
  List<dynamic> prestations = [];
  final storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _fetchPrestations();
  }

  Future<void> _fetchPrestations() async {
    final url =
        Uri.parse('http://10.0.2.2:8080/api/v1/${widget.garageId}/prestations');

    // Récupérer le accessToken depuis flutter_secure_storage
    final accessToken = await storage.read(key: 'accessToken');

    if (accessToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Access Token not found.')),
      );
      return;
    }

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken', // Ajouter le Bearer token ici
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        prestations = jsonDecode(response.body);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load prestations')),
      );
    }
  }

  // Étape 2 : Fonction de suppression d'une prestation avec le Bearer Token
  Future<void> _deletePrestation(String prestationId) async {
    final url =
        Uri.parse('http://10.0.2.2:8080/api/v1/prestation/$prestationId');
    final accessToken = await storage.read(key: 'accessToken');

    if (accessToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Access Token not found.')),
      );
      return;
    }

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken', // Ajout du Bearer Token ici
      },
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Prestation deleted successfully')),
      );
      // Rafraîchir la liste après suppression
      _fetchPrestations();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete prestation')),
      );
    }
  }

  // Étape 3 : Ajouter une boîte de dialogue de confirmation avant la suppression
  Future<void> _confirmDelete(String prestationId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // L'utilisateur doit confirmer ou annuler
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete this prestation?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Fermer la boîte de dialogue
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop(); // Fermer la boîte de dialogue
                _deletePrestation(
                    prestationId); // Appeler la fonction de suppression
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToUpdatePage(Map<String, dynamic> prestation) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdatePrestationPage(prestation: prestation),
      ),
    );

    if (result == true) {
      _fetchPrestations(); // Rafraîchir la liste après la mise à jour
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Prestations du Garage ID : ${widget.garageId}'),
      ),
      body: ListView.builder(
        itemCount: prestations.length,
        itemBuilder: (context, index) {
          final prestation = prestations[index];
          return Column(
            children: [
              ListTile(
                title: Text(prestation['title']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Price: ${prestation['price']}'),
                    Text('Description: ${prestation['description']}'),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => _confirmDelete(prestation[
                              '_id']), // Bouton Delete avec confirmation
                          child: Text('Delete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors
                                .red, // Couleur rouge pour le bouton de suppression
                          ),
                        ),
                        SizedBox(width: 10), // Espace entre les boutons
                        // Un bouton Update sera ajouté ici plus tard
                        ElevatedButton(
                          onPressed: () => _navigateToUpdatePage(
                              prestation), // Bouton Update
                          child: Text('Update'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors
                                .blue, // Couleur bleue pour le bouton de mise à jour
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Divider(), // Ajoute un trait de séparation entre chaque prestation
            ],
          );
        },
      ),
    );
  }
}
