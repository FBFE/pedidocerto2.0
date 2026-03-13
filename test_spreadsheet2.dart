// ignore_for_file: avoid_print
import 'dart:io';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

void main() {
  var file = r'c:\Users\fabianoeugenio\Downloads\ListaRenem.xlsx';
  var bytes = File(file).readAsBytesSync();
  
  var decoder = SpreadsheetDecoder.decodeBytes(bytes);
  var sheetName = decoder.tables.keys.first;
  print('Sheet: $sheetName');
  var sheet = decoder.tables[sheetName]!;
  
  for (var row = 0; row < 10 && row < sheet.maxRows; row++) {
    var rowData = sheet.rows[row];
    print('Row $row: $rowData');
  }
}
