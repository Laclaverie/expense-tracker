/// Turns a raw statement description into a stable merchant key and a
/// display name: `TIM HORTONS #8517` -> `TIM HORTONS` / `Tim Hortons`.
class MerchantName {
  const MerchantName(this.key, this.display);

  /// Uppercase, no accents, no store numbers or references. Used to remember
  /// a merchant's category.
  final String key;
  final String display;

  @override
  String toString() => display;
}

/// Payment processors written before the merchant: `SQ *FERME`, `GOOGLE *YouTube`.
const _processors = {'SQ', 'GDP', 'BKG', 'PAYPAL', 'GOOGLE', 'TST', 'DD', 'SP', 'PY', 'IC', 'ZTL', 'CLR'};

/// Known merchants: key prefix -> display name. Longest prefix wins.
const merchantAliases = {
  'TIM HORTONS': 'Tim Hortons',
  'STARBUCKS': 'Starbucks',
  'MCDONALD': "McDonald's",
  'IGA': 'IGA',
  'MAXI': 'Maxi',
  'METRO': 'Metro',
  'PROVIGO': 'Provigo',
  'SUPER C': 'Super C',
  'COSTCO WHOLESALE': 'Costco',
  'COSTCO ESSENCE': 'Costco Essence',
  'SAQ': 'SAQ',
  'SHELL': 'Shell',
  'PETRO-CANADA': 'Petro-Canada',
  'LYFT': 'Lyft',
  'UBER': 'Uber',
  'AIRBNB': 'Airbnb',
  'HOTEL AT BOOKING': 'Booking.com',
  'BOOKING': 'Booking.com',
  'AIR CAN': 'Air Canada',
  'YOUTUBE': 'YouTube',
  'PATREON': 'Patreon',
  'NETFLIX': 'Netflix',
  'SPOTIFY': 'Spotify',
  'VIRGIN PLUS': 'Virgin Plus',
  'ROOTS': 'Roots',
  'AMZN': 'Amazon',
  'AMAZON': 'Amazon',
  'TGTG': 'Too Good To Go',
  'RTM': 'RTM',
  'STM': 'STM',
  'DESJARDINS ASS': 'Desjardins Assurances',
  'COUCHE-TARD': 'Couche-Tard',
  'PREMIERE MOISSON': 'Première Moisson',
  'T&T SUPERMARKET': 'T&T Supermarket',
  'DOLLARAMA': 'Dollarama',
  'CANADIAN TIRE': 'Canadian Tire',
  'LIBRAIRIE RENAUD BRAY': 'Renaud-Bray',
  'RENAUD-BRAY': 'Renaud-Bray',
  'WESTJET': 'WestJet',
  'PORTER': 'Porter',
  'BIXI': 'Bixi',
  'COMMUNAUTO': 'Communauto',
  'BUDGET': 'Budget',
  'STEAMGAMES': 'Steam',
  'STEAM': 'Steam',
  'BCF': 'BC Ferries',
  'PARKS/PARCS CANADA': 'Parks Canada',
  'SAAQ': 'SAAQ',
  'VRBO': 'Vrbo',
  'A&W': 'A&W',
  'SUBWAY': 'Subway',
  'BURGER KING': 'Burger King',
  'KFC': 'KFC',
  'TICKETMASTER': 'Ticketmaster',
  'EVENBRITE': 'Eventbrite',
  'DECATHLON': 'Decathlon',
  'SPORT EXPERT': 'Sport Expert',
  'REVENU QUEBEC': 'Revenu Québec',
  'EXPEDIA': 'Expedia',
  'HOSTELWORLD': 'Hostelworld',
};

final _accents = {
  'À': 'A', 'Â': 'A', 'Ä': 'A', 'Ç': 'C', 'É': 'E', 'È': 'E', 'Ê': 'E', 'Ë': 'E', //
  'Î': 'I', 'Ï': 'I', 'Ô': 'O', 'Ö': 'O', 'Ù': 'U', 'Û': 'U', 'Ü': 'U', 'Ÿ': 'Y',
};

String stripAccents(String s) => s.toUpperCase().split('').map((c) => _accents[c] ?? c).join();

MerchantName normalizeMerchant(String raw) {
  // Cleaned with accents kept (for display); the key drops them.
  var s = raw.toUpperCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  final star = s.indexOf('*');
  if (star > 0) {
    final before = s.substring(0, star).trim();
    final after = s.substring(star + 1).trim();
    s = _processors.contains(stripAccents(before)) && after.isNotEmpty ? after : before;
  }
  final words = [
    for (final w in s.split(' '))
      if (!RegExp(r'^#?\d').hasMatch(w) && // store numbers, references
          !RegExp(r'^[A-Z]{1,2}\d+$').hasMatch(w) && // W515, C03028
          !RegExp(r'^[X9]{6,}$').hasMatch(w)) // anonymized references
        w.replaceAll(RegExp(r'\d{3,}$'), ''), // SAQ23185 -> SAQ
  ].where((w) => w.isNotEmpty).toList();
  final cleaned = words.join(' ').replaceAll(RegExp(r'[\s\-/.,]+$'), '').trim();
  final key = stripAccents(cleaned);
  if (key.isEmpty) return MerchantName(stripAccents(s), s);
  String? alias;
  var best = 0;
  for (final MapEntry(key: prefix, value: name) in merchantAliases.entries) {
    if (!key.startsWith(prefix) || prefix.length <= best) continue;
    if (key.length == prefix.length || !RegExp('[A-Z0-9]').hasMatch(key[prefix.length])) {
      alias = name;
      best = prefix.length;
    }
  }
  return alias != null ? MerchantName(stripAccents(alias), alias) : MerchantName(key, _titleCase(cleaned));
}

const _keepUpper = {
  'KFC',
  'MEC',
  'SAAQ',
  'SAQ',
  'IGA',
  'RTM',
  'STM',
  'QC',
  'SA',
  'BMO',
  'TD',
  'RBC',
  'LCL',
  'SNCF',
  'RATP',
  'GA',
};

String _titleCase(String s) => s
    .split(' ')
    .map((w) {
      if (_keepUpper.contains(w) || w.length <= 1) return w;
      return w
          .split('-')
          .map((p) => p.isEmpty ? p : p[0] + p.substring(1).toLowerCase())
          .join('-')
          .replaceAllMapped(RegExp(r"'(\w)"), (m) => "'${m[1]!.toLowerCase()}");
    })
    .join(' ');
