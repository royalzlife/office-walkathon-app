import 'package:gsheets/gsheets.dart';

class SheetsService {
  // ❗️ IMPORTANT: Replace the placeholder text below with your actual credentials.
  static const _credentials = r'''
  {
    "type": "service_account",
    "project_id": "your-project-id",
    "private_key_id": "your-private-key-id",
    "private_key": "-----BEGIN PRIVATE KEY-----\nYOUR_PRIVATE_KEY\n-----END PRIVATE KEY-----\n",
    "client_email": "your-client-email@your-project-id.iam.gserviceaccount.com",
    "client_id": "your-client-id",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/your-client-email%40your-project-id.iam.gserviceaccount.com"
  }
  ''';

  // ❗️ IMPORTANT: Replace this with your actual Google Sheet ID.
  static const _spreadsheetId = 'your_spreadsheet_id';

  final GSheets _gsheets = GSheets(_credentials);
  Spreadsheet? _spreadsheet;

  // Initializes the connection to your specific spreadsheet
  Future<void> _init() async {
    _spreadsheet ??= await _gsheets.spreadsheet(_spreadsheetId);
  }

  // Appends a new row to the 'Results' sheet with the final data
  Future<void> uploadToSheet(String name, int steps) async {
    await _init();
    final sheet = _spreadsheet!.worksheetByTitle('Results') ?? await _spreadsheet!.addWorksheet('Results');
    
    final firstRow = await sheet.values.row(1, fromColumn: 1);
    if (firstRow.isEmpty) {
        await sheet.values.insertRow(1, ['Name', 'Steps', 'Timestamp']);
    }

    await sheet.values.appendRow([name, steps, DateTime.now().toIso8601String()]);
  }
}