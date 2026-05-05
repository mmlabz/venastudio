import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_printer/flutter_bluetooth_printer.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';
import 'package:printing/printing.dart';

void printReceipt(
  Printer printer, {
  String? shop,
  String? ticket,
  Map<String, dynamic>? details,
}) async {
  await Printing.directPrintPdf(
    printer: printer,
    onLayout: (format) {
      return _generateReceipt(
        format: format,
        shop: shop ?? 'Shop Name',
        ticket: (ticket != null) ? 'Ticket $ticket' : 'Ticket',
        details: details,
      );
    },
  );
}

void printBluetoothReceipt(
  BluetoothDevice printer, {
  String? shop,
  String? ticket,
  Map<String, dynamic>? details,
}) async {
  final pData = _generateBluetoothReceipt(
    format: PdfPageFormat.roll57,
    shop: shop ?? 'Shop Name',
    ticket: ticket ?? 'Ticket',
    details: details,
  );
  await FlutterBluetoothPrinter.printBytes(
    address: printer.address,
    data: pData,
    keepConnected: true,
  );
}

Future<Uint8List> _generateReceipt({
  required PdfPageFormat format,
  required String shop,
  required String ticket,
  required Map<String, dynamic>? details,
}) async {
  final pdf = Document(version: PdfVersion.pdf_1_5, compress: true);
  final font = await PdfGoogleFonts.nunitoExtraLight();
  final imageByte = await rootBundle.load('assets/images/logo.jpg');
  final logo = Image(MemoryImage(imageByte.buffer.asUint8List()));

  final now = DateFormat.yMd().add_jm().format(DateTime.now());
  final nowF = now.substring(0, now.length - 3);
  final ext = now.substring(now.length - 3).trim() == 'PM' ? ' PM' : 'AM';

  pdf.addPage(
    Page(
      pageFormat: format,
      orientation: PageOrientation.portrait,
      margin: EdgeInsets.zero,
      build: (context) {
        return Column(
          children: [
            Container(alignment: Alignment.center, height: 15, child: logo),
            SizedBox(height: 5),
            Text(
              shop,
              style: TextStyle(font: font, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              ticket,
              style: TextStyle(
                font: font,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              details?['total_price'] ?? 'Ksh 0.00',
              style: TextStyle(
                font: font,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  for (final item in details?['items'] ?? []) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['name'],
                            style: TextStyle(font: font),
                          ),
                        ),
                        SizedBox(
                          width: 30,
                          child: Text(
                            ' ·  ${item['quantity']}',
                            style: TextStyle(font: font),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    Divider(thickness: .2, height: 6),
                  ],
                ],
              ),
            ),
            Text(
              '$nowF$ext',
              style: TextStyle(
                font: font,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Text('Thank you', style: TextStyle(font: font, fontSize: 10)),
            SizedBox(height: 20),
            Text('.', style: TextStyle(font: font, fontSize: 10)),
          ],
        );
      },
    ),
  );
  return pdf.save();
}

Uint8List _generateBluetoothReceipt({
  required PdfPageFormat format,
  required String shop,
  required String ticket,
  required Map<String, dynamic>? details,
}) {
  final now = DateFormat.yMd().add_jm().format(DateTime.now());
  final nowF = now.substring(0, now.length - 3);
  final ext = now.substring(now.length - 3).trim() == 'PM' ? ' PM' : 'AM';
  final items = details?['items'] ?? [];
  List<int> bytes = [];
  bytes.addAll([0x1B, 0x61, 0x01]);
  // Double height and width text
  bytes.addAll([0x1B, 0x21, 0x30]);
  bytes.addAll("$shop\n".codeUnits);

  // Cancel double height and width
  // bytes.addAll([0x1B, 0x21, 0x00]);
  bytes.addAll([0x1B, 0x64, 0x02]); // Feed 2 lines
  // bytes.addAll("Address Line 1\n".codeUnits);
  // bytes.addAll("Address Line 2\n".codeUnits);
  // bytes.addAll([0x1B, 0x64, 0x01]); // Feed 1 line
  bytes.addAll("Ticket $ticket\n".codeUnits);
  bytes.addAll("${details?['total_price'] ?? 'Ksh 0.00'}\n".codeUnits);
  bytes.addAll([0x1B, 0x64, 0x01]); // Feed 1 line

  // Left alignment
  bytes.addAll([0x1B, 0x61, 0x00]);

  // Bold text on and emphasized mode
  // bytes.addAll([0x1B, 0x45, 0x01]);
  // bytes.addAll([0x1B, 0x21, 0x08]);
  // bytes.addAll("Receipt No: 0001\n".codeUnits);

  // Normal text
  bytes.addAll([0x1B, 0x45, 0x00]);
  bytes.addAll([0x1B, 0x21, 0x00]);
  // bytes.addAll("Date: 2024-08-12\n".codeUnits);

  // Set horizontal tabs
  // bytes.addAll([0x1B, 0x44, 0x00, 0x08, 0x10, 0x18, 0x00]);
  // bytes.addAll("Item          Qty   \n".codeUnits);
  // bytes.addAll([0x1B, 0x64, 0x01]); // Feed 1 line
  if (items.isNotEmpty) {
    bytes.addAll("-------------------------------\n".codeUnits);
    for (final item in items) {
      bytes.addAll("${item['name']}  x ${item['quantity']}  \n".codeUnits);
      bytes.addAll([0x1B, 0x64, 0x01]); // Feed 1 line
    }
    // bytes.addAll("Item A          2    \n".codeUnits);
    // bytes.addAll([0x1B, 0x64, 0x01]); // Feed 1 line
    // bytes.addAll("Item B          1    \n".codeUnits);
    // bytes.addAll([0x1B, 0x64, 0x01]); // Feed 1 line
    bytes.addAll("-------------------------------\n".codeUnits);
  }

  // Bold text for total
  // bytes.addAll([0x1B, 0x45, 0x01]);
  // bytes.addAll("Total:                \$35.00\n".codeUnits);
  // bytes.addAll([0x1B, 0x45, 0x00]); // Bold off
  bytes.addAll([0x1B, 0x64, 0x01]); // Feed 1 line

  // Center alignment for closing message
  bytes.addAll([0x1B, 0x61, 0x01]);
  bytes.addAll("$nowF$ext\n".codeUnits);
  bytes.addAll("Thank you\n".codeUnits);
  bytes.addAll([0x1B, 0x64, 0x03]); // Feed 3 lines

  // Cut paper
  bytes.addAll([0x1B, 0x69]);
  return Uint8List.fromList(bytes);
}
