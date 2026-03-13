// ignore_for_file: avoid_print
import 'dart:io';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

void main() {
  var file = r'c:\Users\fabianoeugenio\Downloads\LISTA RENEM.xlsx';
  var bytes = File(file).readAsBytesSync();
  
  var decoder = SpreadsheetDecoder.decodeBytes(bytes);
  for (var table in decoder.tables.keys) {
    print('Sheet: $table');
    var sheet = decoder.tables[table]!;
    for (var row = 0; row < 5 && row < sheet.maxRows; row++) {
      var rowData = sheet.rows[row];
      print(rowData);
    }
    break;
  }
}
