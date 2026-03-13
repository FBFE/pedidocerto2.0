const xlsx = require('xlsx');
const fs = require('fs');

try {
  console.log('Lendo o arquivo XLSX...');
  const workbook = xlsx.readFile('c:/Users/fabianoeugenio/Downloads/LISTA RENEM.xlsx');
  
  const sheet_name_list = workbook.SheetNames;
  const sheet = workbook.Sheets[sheet_name_list[0]];
  
  console.log('Convertendo para CSV...');
  const csvData = xlsx.utils.sheet_to_csv(sheet, { FS: ';' }); // Usando ponto e vírgula como separador
  
  const outputPath = 'c:/Users/fabianoeugenio/Downloads/LISTA_RENEM_FORMATADA.csv';
  fs.writeFileSync(outputPath, csvData, 'utf8');
  
  console.log('Arquivo convertido com sucesso para: ' + outputPath);
} catch (e) {
  console.error('Erro:', e);
}
