import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:inventary/data/auth.dart';
import 'package:inventary/presentation/stock_management.dart';

// BLoC State
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


        // Convert data into a list of maps, handling missing values
        List<Map<String, dynamic>> inventory = values.skip(1).map((row) {
          log("Row Data: $row");
          return {
            "Item Name": row.isNotEmpty ? row[0] ?? '' : '',
            "Quantity": row.length > 1 ? row[1] ?? '0' : '0',
            "Last Updated": row.length > 2 ? row[2] ?? 'N/A' : 'N/A',
            "Threshold": row.length > 3 ? row[3] ?? '5' : '5',
          };
        }).toList();

        log("Parsed Inventory Data: $inventory");
        emit(InventoryLoaded(inventory));
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
    fetchInventory(); // Refresh inventory after deletion
  } catch (e) {
    log("Error deleting item: $e");
  }
}

}


// HomeScreen UI
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Inventory Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
      ),
      body: BlocProvider(
        create: (context) => InventoryCubit()..fetchInventory(),
        child: BlocBuilder<InventoryCubit, InventoryState>(
          builder: (context, state) {
            if (state is InventoryLoading) {
              return Center(child: CircularProgressIndicator());
            } else if (state is InventoryLoaded) {
              return Padding(
                padding: const EdgeInsets.all(12.0),
                child: ListView.builder(
                  itemCount: state.inventory.length,
                  itemBuilder: (context, index) {
                    final item = state.inventory[index];
                    log("Inventory Item: $item");
                    final int quantity = int.tryParse(item['Quantity'].toString()) ?? 0;
                    final int threshold = int.tryParse(item['Threshold'].toString()) ?? 5;
                    final bool isLowStock = quantity < threshold;

                    return Card(
                      elevation: 4,
                      margin: EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        leading: CircleAvatar(
                          backgroundColor: isLowStock ? Colors.redAccent : Colors.green,
                          child: Icon(
                            isLowStock ? Icons.warning_rounded : Icons.check_circle,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          item['Item Name'] ?? 'Unknown Item',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        subtitle: Text(
                          "Last Updated: ${ (item['Last Updated'] ?? 'N/A').toString()}",
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                        trailing: Wrap(
                          spacing: 10,
                          children: [
                            Text('Stock: $quantity',
                                style: TextStyle(
                                  color: isLowStock ? Colors.red : Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                )),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => context.read<InventoryCubit>().deleteItem(index+2),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            } else {
              return Center(
                child: Text(
                  'Error fetching inventory.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                ),
              );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddItemScreen()),
          );
        },
        icon: Icon(Icons.add, color: Colors.white),
        label: Text(
          'Manage Stock',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }
}
