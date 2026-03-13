const xlsx = require('xlsx');
const workbook = xlsx.readFile('c:/Users/fabianoeugenio/Downloads/LISTA RENEM.xlsx');
const sheet_name_list = workbook.SheetNames;
console.log('Sheets:', sheet_name_list);
const data = xlsx.utils.sheet_to_json(workbook.Sheets[sheet_name_list[0]], {header: 1});
console.log('First row:', data[0]);
console.log('Second row:', data[1]);
console.log('Third row:', data[2]);
