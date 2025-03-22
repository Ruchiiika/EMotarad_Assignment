import 'dart:convert';
import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:inventary/data/auth.dart';


// BLoC States
abstract class InventoryState {}

class InventoryLoading extends InventoryState {}

class InventoryLoaded extends InventoryState {
  final List<Map<String, dynamic>> inventory;
  InventoryLoaded(this.inventory);
}

class InventoryError extends InventoryState {}

// BLoC Cubit
class InventoryCubit extends Cubit<InventoryState> {
  InventoryCubit() : super(InventoryLoading());

  Future<void> fetchInventory() async {
    try {
      final response = await http.get(Uri.parse(
          'https://sheets.googleapis.com/v4/spreadsheets/1egyhiw-f7WTN-ZkeQjKHWE48webpOVLeri3H486mslw/values/Sheet1?key=AIzaSyC7hIbs-eDGBVA-4UDA1Aggw_YEf_RuaS8'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (!jsonResponse.containsKey('values') || jsonResponse['values'].isEmpty) {
          log("Missing 'values' key in API response");
          emit(InventoryError());
          return;
        }

        final List<dynamic> values = jsonResponse['values'];
        final List<String> headers = List<String>.from(values[0]);
          log(headers.join());
        if (values.isEmpty) {
          log("API response contains an empty values array");
          emit(InventoryError());
          return;
        }

        // Convert data into a list of maps
         List<Map<String, dynamic>?> inventory = values.skip(1).map((row) {
        if (row.isEmpty || row.every((cell) => cell.toString().trim().isEmpty)) {
          return null; // Mark for removal
        }
        return {
          "Item Name": row.isNotEmpty ? row[0] ?? '' : '',
          "Quantity": row.length > 1 ? row[1] ?? '0' : '0',
          "Last Updated": row.length > 2 ? row[2] ?? 'N/A' : 'N/A',
          "Threshold": row.length > 3 ? row[3] ?? '5' : '5',
        };
      }).where((item) => item != null).toList();

        log("Parsed Inventory Data: $inventory");
        emit(InventoryLoaded(inventory.cast<Map<String, dynamic>>()));

      } else {
        log("API Error: ${response.statusCode} - ${response.body}");
        emit(InventoryError());
      }
    } catch (e) {
      log("Error fetching inventory: $e");
      emit(InventoryError());
    }
  }

  Future<void> deleteItem(int rowIndex) async {
  try {
    await GoogleSheetsHelper.deleteRow(rowIndex);

    // Directly remove the item from the inventory list to update UI instantly
    if (state is InventoryLoaded) {
      List<Map<String, dynamic>> updatedInventory =
          List.from((state as InventoryLoaded).inventory);

      if (rowIndex - 2 >= 0 && rowIndex - 2 < updatedInventory.length) {
        updatedInventory.removeAt(rowIndex - 2);
      }

      emit(InventoryLoaded(updatedInventory)); // Update UI instantly
    }
  } catch (e) {
    log("Error deleting item: $e");
  }
}
}
