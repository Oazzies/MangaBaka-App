part 'prepared_query_part.dart';

class SearchUtils {
  SearchUtils._();

  static PreparedQuery prepare(String query) => PreparedQuery._(query);

  /// [keepApostrophes] keeps quotes (as ') so a query typed with one only matches candidates with one.
  static String normalize(String input, {bool keepApostrophes = false}) {
    if (input.isEmpty) return '';

    final buf = StringBuffer();
    var lastWasSpace = true; // suppresses leading whitespace

    for (final rune in input.runes) {
      var cp = rune;

      // Full-width space -> ASCII space.
      if (cp == 0x3000) {
        cp = 0x20;
      } else if (cp >= 0xFF01 && cp <= 0xFF5E) {
        // Full-width ASCII variants -> half-width ASCII.
        cp -= 0xFEE0;
      }

      // Skip combining diacritical marks (e.g. NFD-decomposed macrons/accents).
      if (cp >= 0x0300 && cp <= 0x036F) {
        continue;
      }

      if (_apostrophesAndQuotes.contains(cp)) {
        if (keepApostrophes) {
          buf.writeCharCode(0x27);
          lastWasSpace = false;
        }
        continue;
      }

      if (cp < 0x80) {
        if (cp >= 0x41 && cp <= 0x5A) {
          cp += 0x20;
        }
        if ((cp >= 0x61 && cp <= 0x7A) || (cp >= 0x30 && cp <= 0x39)) {
          buf.writeCharCode(cp);
          lastWasSpace = false;
        } else {
          if (!lastWasSpace) {
            buf.writeCharCode(0x20);
            lastWasSpace = true;
          }
        }
        continue;
      }

      final folded = _latinFold[cp];
      if (folded != null) {
        buf.write(folded);
        lastWasSpace = false;
        continue;
      }

      if (_unicodeSeparators.contains(cp)) {
        if (!lastWasSpace) {
          buf.writeCharCode(0x20);
          lastWasSpace = true;
        }
        continue;
      }

      final ch = String.fromCharCode(cp).toLowerCase();
      buf.write(ch);
      lastWasSpace = false;
    }

    final result = buf.toString();
    if (result.isEmpty) return '';
    return lastWasSpace ? result.substring(0, result.length - 1) : result;
  }

  static bool containsApostrophe(String input) {
    for (final rune in input.runes) {
      var cp = rune;
      if (cp >= 0xFF01 && cp <= 0xFF5E) cp -= 0xFEE0;
      if (_apostrophesAndQuotes.contains(cp)) return true;
    }
    return false;
  }

  static const Set<int> _apostrophesAndQuotes = {
    0x0027, // '
    0x0022, // "
    0x0060, // `
    0x00B4, // ´
    0x02BC, // ʼ
    0x2018, // ‘
    0x2019, // ’
    0x201C, // “
    0x201D, // ”
    0x2032, // ′
    0x2033, // ″
  };

  static const Set<int> _unicodeSeparators = {
    0x00A0, // non-breaking space
    0x00B7, // ·
    0x00D7, // ×
    0x00F7, // ÷
    0x2010, // ‐
    0x2011, // ‑
    0x2012, // ‒
    0x2013, // –
    0x2014, // —
    0x2015, // ―
    0x2022, // •
    0x2026, // …
    0x2212, // −
    0x2605, // ★
    0x2606, // ☆
    0x2661, // ♡
    0x2665, // ♥
    0x266A, // ♪
    0x266B, // ♫
    0x3001, // 、
    0x3002, // 。
    0x3008, // 〈
    0x3009, // 〉
    0x300A, // 《
    0x300B, // 》
    0x300C, // 「
    0x300D, // 」
    0x300E, // 『
    0x300F, // 』
    0x3010, // 【
    0x3011, // 】
    0x301C, // 〜
    0x30FB, // ・
  };

  static const Map<int, String> _latinFold = {
    0x00C0: 'a', 0x00C1: 'a', 0x00C2: 'a', 0x00C3: 'a', 0x00C4: 'a',
    0x00C5: 'a', 0x0100: 'a', 0x0102: 'a', 0x0104: 'a',
    0x00E0: 'a', 0x00E1: 'a', 0x00E2: 'a', 0x00E3: 'a', 0x00E4: 'a',
    0x00E5: 'a', 0x0101: 'a', 0x0103: 'a', 0x0105: 'a',
    0x00C7: 'c', 0x0106: 'c', 0x0108: 'c', 0x010A: 'c', 0x010C: 'c',
    0x00E7: 'c', 0x0107: 'c', 0x0109: 'c', 0x010B: 'c', 0x010D: 'c',
    0x010E: 'd', 0x0110: 'd',
    0x010F: 'd', 0x0111: 'd',
    0x00C8: 'e', 0x00C9: 'e', 0x00CA: 'e', 0x00CB: 'e', 0x0112: 'e',
    0x0114: 'e', 0x0116: 'e', 0x0118: 'e', 0x011A: 'e',
    0x00E8: 'e', 0x00E9: 'e', 0x00EA: 'e', 0x00EB: 'e', 0x0113: 'e',
    0x0115: 'e', 0x0117: 'e', 0x0119: 'e', 0x011B: 'e',
    0x011C: 'g', 0x011E: 'g', 0x0120: 'g', 0x0122: 'g',
    0x011D: 'g', 0x011F: 'g', 0x0121: 'g', 0x0123: 'g',
    0x0124: 'h', 0x0126: 'h',
    0x0125: 'h', 0x0127: 'h',
    0x00CC: 'i', 0x00CD: 'i', 0x00CE: 'i', 0x00CF: 'i', 0x0128: 'i',
    0x012A: 'i', 0x012C: 'i', 0x012E: 'i', 0x0130: 'i',
    0x00EC: 'i', 0x00ED: 'i', 0x00EE: 'i', 0x00EF: 'i', 0x0129: 'i',
    0x012B: 'i', 0x012D: 'i', 0x012F: 'i', 0x0131: 'i',
    0x0134: 'j', 0x0135: 'j',
    0x0136: 'k', 0x0137: 'k',
    0x0139: 'l', 0x013B: 'l', 0x013D: 'l', 0x013F: 'l', 0x0141: 'l',
    0x013A: 'l', 0x013C: 'l', 0x013E: 'l', 0x0140: 'l', 0x0142: 'l',
    0x00D1: 'n', 0x0143: 'n', 0x0145: 'n', 0x0147: 'n',
    0x00F1: 'n', 0x0144: 'n', 0x0146: 'n', 0x0148: 'n',
    0x00D2: 'o', 0x00D3: 'o', 0x00D4: 'o', 0x00D5: 'o', 0x00D6: 'o',
    0x00D8: 'o', 0x014C: 'o', 0x014E: 'o', 0x0150: 'o',
    0x00F2: 'o', 0x00F3: 'o', 0x00F4: 'o', 0x00F5: 'o', 0x00F6: 'o',
    0x00F8: 'o', 0x014D: 'o', 0x014F: 'o', 0x0151: 'o',
    0x0154: 'r', 0x0156: 'r', 0x0158: 'r',
    0x0155: 'r', 0x0157: 'r', 0x0159: 'r',
    0x015A: 's', 0x015C: 's', 0x015E: 's', 0x0160: 's',
    0x015B: 's', 0x015D: 's', 0x015F: 's', 0x0161: 's',
    0x0162: 't', 0x0164: 't', 0x0166: 't',
    0x0163: 't', 0x0165: 't', 0x0167: 't',
    0x00D9: 'u', 0x00DA: 'u', 0x00DB: 'u', 0x00DC: 'u', 0x0168: 'u',
    0x016A: 'u', 0x016C: 'u', 0x016E: 'u', 0x0170: 'u', 0x0172: 'u',
    0x00F9: 'u', 0x00FA: 'u', 0x00FB: 'u', 0x00FC: 'u', 0x0169: 'u',
    0x016B: 'u', 0x016D: 'u', 0x016F: 'u', 0x0171: 'u', 0x0173: 'u',
    0x0174: 'w', 0x0175: 'w',
    0x00DD: 'y', 0x0176: 'y', 0x0178: 'y',
    0x00FD: 'y', 0x00FF: 'y', 0x0177: 'y',
    0x0179: 'z', 0x017B: 'z', 0x017D: 'z',
    0x017A: 'z', 0x017C: 'z', 0x017E: 'z',
    0x00DF: 'ss', // ß
    0x1E9E: 'ss', // ẞ
    0x00C6: 'ae', 0x00E6: 'ae', // Æ / æ
    0x0152: 'oe', 0x0153: 'oe', // Œ / œ
  };
}
