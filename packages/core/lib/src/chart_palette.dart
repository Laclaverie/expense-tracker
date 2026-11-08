/// Chart colors as ARGB ints (no Flutter): the desktop and phone apps wrap
/// them in `Color`. Dataviz palette, validated for color-vision deficiency.
library;

/// Category groups with a fixed chart color (categorical palette, slots 1–7,
/// validated for color-vision deficiency in this order). Every other group is
/// shown as "Other"; uncategorized spending has its own (lighter) neutral.
/// Color follows the group, never its rank.
const chartGroups = ['food', 'housing', 'transport', 'travel', 'leisure', 'shopping', 'people'];

/// Chart series keys besides [chartGroups].
const otherSeries = 'other';
const uncategorizedSeries = 'none';

const lightPalette = [0xFF2A78D6, 0xFFEB6834, 0xFF1BAF7A, 0xFFEDA100, 0xFFE87BA4, 0xFF008300, 0xFF6250D6];
const darkPalette = [0xFF3987E5, 0xFFD95926, 0xFF199E70, 0xFFC98500, 0xFFD55181, 0xFF008300, 0xFF9085E9];
const otherLight = 0xFF9A9893;
const otherDark = 0xFF6F6E69;
const noneLight = 0xFFD3D1CA;
const noneDark = 0xFFB4B2AB;

/// Group id of a category id: `food.coffee` -> `food`.
String groupOf(String? categoryId) =>
    categoryId == null || categoryId.isEmpty || categoryId == uncategorizedSeries ? '' : categoryId.split('.').first;

/// Chart series of a category or group id: a chart group, other, or none.
String seriesOf(String? categoryOrGroup) {
  final g = groupOf(categoryOrGroup);
  if (g.isEmpty) return uncategorizedSeries;
  return chartGroups.contains(g) ? g : otherSeries;
}
