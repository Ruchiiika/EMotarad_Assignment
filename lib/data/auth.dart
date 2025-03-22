import 'dart:convert';
import 'dart:developer';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis/sheets/v4.dart';
import 'package:googleapis_auth/auth_io.dart';

class GoogleSheetsHelper {
  static Future<AuthClient> getAuthClient() async {
    try {
      // Load JSON file from assets
      String jsonKey = await rootBundle.loadString('assets/path/service.json');

      // Parse JSON credentials
      final credentials = ServiceAccountCredentials.fromJson(json.decode(jsonKey));

      // Authenticate using Google Sheets API
      final client = await clientViaServiceAccount(
        credentials,
        [SheetsApi.spreadsheetsScope],
      );

      return client;
    } catch (e) {
      log("Error loading service account: $e");
      rethrow;
    }
  }

  // Function to delete a row
  static Future<void> deleteRow(int rowIndex) async {
    try {
      final client = await getAuthClient();
      final sheetsApi = SheetsApi(client);

      final spreadsheetId = "1egyhiw-f7WTN-ZkeQjKHWE48webpOVLeri3H486mslw";
      final range = "Sheet1!A$rowIndex:D$rowIndex";

      await sheetsApi.spreadsheets.values.clear(ClearValuesRequest(), spreadsheetId, range);
      log("Row $rowIndex deleted successfully!");
    } catch (e) {
      log("Error deleting row: $e");
    }
  }
}
