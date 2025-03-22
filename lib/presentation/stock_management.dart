import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class AddItemScreen extends StatefulWidget {
  @override
  _AddItemScreenState createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController lastUpdatedController = TextEditingController();
  bool inStock = true; // Checkbox for stock availability

  final String webAppUrl =
      "https://script.google.com/macros/s/AKfycbzaCho3EPBMQWM_EuR29VMiDXHl_KoR7EUs-kai27_ySHJQi-biN4DNBfoPxj6lwZ50/exec"; // Replace with your actual Web App URL

  Future<void> addItem() async {
  String itemId = const Uuid().v4();
  String formattedDate =
      DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

  try {
    final response = await http.post(
      Uri.parse(webAppUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "action": "add",
        "name": nameController.text.trim(), // Ensure Name is correct
        "quantity": quantityController.text.trim(),
        "lastUpdated": formattedDate,
        "inStock": inStock ? "Yes" : "No",
        "id": itemId, // Keep ID but not in the UI
      }),
    );

    if (response.statusCode == 200) {
      showSnackBar("Item Added Successfully!");
      clearFields();
    } else {
      //showSnackBar("Error: ${response.body}");
    }
  } catch (e) {
    showSnackBar("Error: $e");
  }
}


  void clearFields() {
    nameController.clear();
    quantityController.clear();
    lastUpdatedController.clear();
    setState(() {
      inStock = true;
    });
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Item to Inventory",
        style: TextStyle(
          color: Colors.white,
          fontSize: 30,
          fontWeight: FontWeight.bold
        ),),
        backgroundColor: Colors.deepPurple,
        leading: Icon(Icons.arrow_back_ios,color: Colors.white,),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          padding: EdgeInsets.all(20),
          height: 320,
          width: 380,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.green,width: 2)
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: "Product Name",
                  enabledBorder: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder()
                ),
              ),
              SizedBox(height: 15),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(hintText: "Quantity",
                enabledBorder: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(),
                  ),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Text("In Stock: ",
                  style: TextStyle(
                    fontSize: 16
                  ),),
                  Checkbox(
                    value: inStock,
                    onChanged: (value) {
                      setState(() {
                        inStock = value!;
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: addItem,
                  child: Text("Add Item",style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
