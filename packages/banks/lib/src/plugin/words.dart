/// Word lists and small text helpers shared by bank plug-ins. Each set is a
/// starting point: a plug-in extends it for its own statements, e.g.
/// `const myStreetWords = {...streetWords, 'IMPASSE'};`.
library;

/// Month abbreviations on French statement lines (`1 MAI`, `22 AOU`), with and
/// without accents.
const frenchMonthAbbreviations = {
  'JAN': 1, 'FEV': 2, 'FÉV': 2, 'MAR': 3, 'AVR': 4, 'MAI': 5, 'JUN': 6, //
  'JUI': 7, 'JUL': 7, 'AOU': 8, 'AOÛ': 8, 'SEP': 9, 'OCT': 10, 'NOV': 11,
  'DEC': 12, 'DÉC': 12,
};

/// Full French month names, lowercase, with and without accents.
const frenchMonthNames = {
  'janvier': 1, 'février': 2, 'fevrier': 2, 'mars': 3, 'avril': 4, 'mai': 5, //
  'juin': 6, 'juillet': 7, 'août': 8, 'aout': 8, 'septembre': 9,
  'octobre': 10, 'novembre': 11, 'décembre': 12, 'decembre': 12,
};

/// Words of a postal address line that are not personal (street types, unit,
/// direction), uppercase. An anonymizer masks every other word of the line.
const streetWords = {
  'RUE', 'AVENUE', 'AV', 'AV.', 'BOUL', 'BOUL.', 'BOULEVARD', 'CHEMIN', 'CH.', 'RANG', 'PLACE', 'MONTEE', //
  'APP', 'APP.', 'APPARTEMENT', 'UNITE', 'UNITÉ', 'BUREAU', 'EST', 'OUEST', 'NORD', 'SUD', 'C.P.',
};

/// First word of a multi-word city (`SAINT LEONARD`, `North Rustico`), uppercase.
const cityPrefixes = {
  'SAINT', 'SAINTE', 'ST', 'ST.', 'STE', 'STE.', 'NEW', 'NORTH', 'SOUTH', 'EAST', 'WEST', 'PORT', 'CAPE', //
  'MOUNT', 'MONT', 'FORT', 'LAC', 'POINTE', 'ILE', 'ÎLE', 'NOTRE', 'BAIE', 'GRAND', 'GRANDE', 'LES', 'LA', 'LE',
  'DOWNTOWN',
};

/// Last word of a multi-word city (`AULDS COVE`, `NIAGARA FALLS`), uppercase.
const citySuffixes = {
  'COVE', 'BAY', 'FALLS', 'HARBOUR', 'HARBOR', 'BEACH', 'LAKE', 'LAKES', 'CITY', 'HILL', 'HILLS', 'RIVER', //
  'VALLEY', 'MILLS', 'CREEK', 'SPRINGS', 'HEIGHTS', 'LANDING', 'CROSSING', 'JUNCTION', 'PARK',
};

/// An all-caps name word (`TREMBLAY`, `O'NEIL`, `JEAN-LUC`), as statements
/// print the holder's name.
bool isUpperName(String s) => RegExp(r"^[A-ZÀ-Ý][A-ZÀ-Ý'\-]+$").hasMatch(s);

/// Whether [words] begins with every word of [prefix], in order.
bool startsWithWords(List<String> words, List<String> prefix) {
  if (words.length < prefix.length) return false;
  for (var i = 0; i < prefix.length; i++) {
    if (words[i] != prefix[i]) return false;
  }
  return true;
}
