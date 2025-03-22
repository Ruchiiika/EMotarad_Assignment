import 'dart:convert';
import 'package:http/http.dart' as http;

class GoogleSheetsService {
  final String scriptUrl = "https://script.google.com/macros/s/AKfycbzaCho3EPBMQWM_EuR29VMiDXHl_KoR7EUs-kai27_ySHJQi-biN4DNBfoPxj6lwZ50/exec";

  // Fetch inventory from Google Sheets
  Future<List<List<dynamic>>> fetchInventory() async {
    final response = await http.get(Uri.parse(scriptUrl + "?action=fetch"));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<List<dynamic>>.from(data['values']);
    } else {
      throw Exception("Failed to load inventory");
    }
  }

  // Save a new item to Google Sheets
  Future<void> saveItem(String name, int quantity, double price, int threshold) async {
    final response = await http.post(
      Uri.parse(scriptUrl + "?action=save"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name,
        "quantity": quantity,
        "price": price,
        "threshold": threshold,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to save item");
    }
  }

  // Update stock quantity in Google Sheets
  Future<void> updateStock(String itemName, int quantity) async {
    final response = await http.post(
      Uri.parse(scriptUrl + "?action=update"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"name": itemName, "quantity": quantity}),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to update stock");
    }
  }
}
