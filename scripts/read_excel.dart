// ignore_for_file: avoid_print
import 'dart:io';
import 'package:excel/excel.dart';

void main() {
  var file = r'c:\Users\fabianoeugenio\Downloads\LISTA RENEM.xlsx';
  var bytes = File(file).readAsBytesSync();
  var excel = Excel.decodeBytes(bytes);

  for (var table in excel.tables.keys) {
    print('Sheet: $table');
    var sheet = excel.tables[table]!;
    for (var row = 0; row < 5 && row < sheet.maxRows; row++) {
      var rowData = sheet.rows[row];
      print(rowData.map((e) => e?.value).toList());
    }
    break;
  }
}
