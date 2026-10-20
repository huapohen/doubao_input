import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'app_state.dart';

/// A single dictionary row. Pinyin is space separated in the source data.
class DictEntry {
  final String w;
  final String p;
  final String flat;
  final String initials;
  final int f;
  late final String t9;

  DictEntry(this.w, this.p, this.f)
      : flat = p.replaceAll(' ', '').toLowerCase(),
        initials = _initialsOf(p) {
    final b = StringBuffer();
    for (final c in flat.codeUnits) {
      final ch = String.fromCharCode(c);
      b.write(_digitOf(ch));
    }
    t9 = b.toString();
  }

  static String _initialsOf(String p) {
    final b = StringBuffer();
    for (final s in p.split(' ')) {
      if (s.isNotEmpty) b.write(s[0]);
    }
    return b.toString();
  }

  static String _digitOf(String ch) {
    const map = {
      'a': '2', 'b': '2', 'c': '2', 'd': '3', 'e': '3', 'f': '3',
      'g': '4', 'h': '4', 'i': '4', 'j': '5', 'k': '5', 'l': '5',
      'm': '6', 'n': '6', 'o': '6', 'p': '7', 'q': '7', 'r': '7', 's': '7',
      't': '8', 'u': '8', 'v': '8', 'w': '9', 'x': '9', 'y': '9', 'z': '9',
    };
    return map[ch] ?? '1';
  }
}

class Cand {
  final String text;
  final String pinyin;
  final double score;
  final String source;
  const Cand(this.text, this.pinyin, this.score, this.source);

  @override
  bool operator ==(Object other) => other is Cand && other.text == text;

  @override
  int get hashCode => text.hashCode;
}

class PinyinEngine {
  static final PinyinEngine instance = PinyinEngine._();
  PinyinEngine._();

  final List<DictEntry> _entries = [];
  final List<DictEntry> _sorted = [];
  final Map<String, List<DictEntry>> _byInitials = {};
  final Map<String, List<DictEntry>> _singleBySyllable = {};
  final Set<String> _syllables = {};
  final Map<String, List<Cand>> _t9Cache = {};
  final Map<String, List<Cand>> _queryCache = {};

  bool loaded = false;
  void clearCache() {
    _queryCache.clear();
    _t9Cache.clear();
  }

  int get entryCount => _entries.length;
  int loadMillis = 0;
  int lastQueryMicros = 0;
  String lastQuery = '';

  Future<void> load() async {
    if (loaded) return;
    final sw = Stopwatch()..start();
    final raw = await rootBundle.loadString('assets/data/pinyin_dict.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final list = data['entries'] as List;
    for (final item in list) {
      final m = item as Map;
      final w = m['w'] as String;
      final p = (m['p'] as String).toLowerCase();
      final f = (m['f'] as num).toInt();
      final e = DictEntry(w, p, f);
      _entries.add(e);
      _byInitials.putIfAbsent(e.initials, () => []).add(e);
      if (w.length == 1) {
        final sy = e.flat;
        _syllables.add(sy);
        _singleBySyllable.putIfAbsent(sy, () => []).add(e);
      }
    }
    _sorted.addAll(_entries);
    _sorted.sort((a, b) {
      final c = a.flat.compareTo(b.flat);
      if (c != 0) return c;
      return b.f.compareTo(a.f);
    });
    for (final l in _byInitials.values) {
      l.sort((a, b) => b.f.compareTo(a.f));
    }
    _syllables.addAll(const [
      'a', 'ai', 'an', 'ang', 'ao', 'ba', 'bai', 'ban', 'bang', 'bao', 'bei',
      'ben', 'beng', 'bi', 'bian', 'biao', 'bie', 'bin', 'bing', 'bo', 'bu',
      'ca', 'cai', 'can', 'cang', 'cao', 'ce', 'cen', 'ceng', 'cha', 'chai',
      'chan', 'chang', 'chao', 'che', 'chen', 'cheng', 'chi', 'chong', 'chou',
      'chu', 'chua', 'chuai', 'chuan', 'chuang', 'chui', 'chun', 'chuo', 'ci',
      'cong', 'cou', 'cu', 'cuan', 'cui', 'cun', 'cuo', 'da', 'dai', 'dan',
      'dang', 'dao', 'de', 'dei', 'deng', 'di', 'dian', 'diao', 'die', 'ding',
      'diu', 'dong', 'dou', 'du', 'duan', 'dui', 'dun', 'duo', 'e', 'ei', 'en',
      'eng', 'er', 'fa', 'fan', 'fang', 'fei', 'fen', 'feng', 'fo', 'fou', 'fu',
      'ga', 'gai', 'gan', 'gang', 'gao', 'ge', 'gei', 'gen', 'geng', 'gong',
      'gou', 'gu', 'gua', 'guai', 'guan', 'guang', 'gui', 'gun', 'guo', 'ha',
      'hai', 'han', 'hang', 'hao', 'he', 'hei', 'hen', 'heng', 'hong', 'hou',
      'hu', 'hua', 'huai', 'huan', 'huang', 'hui', 'hun', 'huo', 'ji', 'jia',
      'jian', 'jiang', 'jiao', 'jie', 'jin', 'jing', 'jiong', 'jiu', 'ju',
      'juan', 'jue', 'jun', 'ka', 'kai', 'kan', 'kang', 'kao', 'ke', 'ken',
      'keng', 'kong', 'kou', 'ku', 'kua', 'kuai', 'kuan', 'kuang', 'kui', 'kun',
      'kuo', 'la', 'lai', 'lan', 'lang', 'lao', 'le', 'lei', 'leng', 'li',
      'lia', 'lian', 'liang', 'liao', 'lie', 'lin', 'ling', 'liu', 'long',
      'lou', 'lu', 'luan', 'lue', 'lun', 'luo', 'lv', 'ma', 'mai', 'man',
      'mang', 'mao', 'me', 'mei', 'men', 'meng', 'mi', 'mian', 'miao', 'mie',
      'min', 'ming', 'miu', 'mo', 'mou', 'mu', 'na', 'nai', 'nan', 'nang',
      'nao', 'ne', 'nei', 'nen', 'neng', 'ni', 'nian', 'niang', 'niao', 'nie',
      'nin', 'ning', 'niu', 'nong', 'nou', 'nu', 'nuan', 'nue', 'nuo', 'nv',
      'o', 'ou', 'pa', 'pai', 'pan', 'pang', 'pao', 'pei', 'pen', 'peng', 'pi',
      'pian', 'piao', 'pie', 'pin', 'ping', 'po', 'pou', 'pu', 'qi', 'qia',
      'qian', 'qiang', 'qiao', 'qie', 'qin', 'qing', 'qiong', 'qiu', 'qu',
      'quan', 'que', 'qun', 'ran', 'rang', 'rao', 're', 'ren', 'reng', 'ri',
      'rong', 'rou', 'ru', 'rua', 'ruan', 'rui', 'run', 'ruo', 'sa', 'sai',
      'san', 'sang', 'sao', 'se', 'sen', 'seng', 'sha', 'shai', 'shan',
      'shang', 'shao', 'she', 'shen', 'sheng', 'shi', 'shou', 'shu', 'shua',
      'shuai', 'shuan', 'shuang', 'shui', 'shun', 'shuo', 'si', 'song', 'sou',
      'su', 'suan', 'sui', 'sun', 'suo', 'ta', 'tai', 'tan', 'tang', 'tao',
      'te', 'teng', 'ti', 'tian', 'tiao', 'tie', 'ting', 'tong', 'tou', 'tu',
      'tuan', 'tui', 'tun', 'tuo', 'wa', 'wai', 'wan', 'wang', 'wei', 'wen',
      'weng', 'wo', 'wu', 'xi', 'xia', 'xian', 'xiang', 'xiao', 'xie', 'xin',
      'xing', 'xiong', 'xiu', 'xu', 'xuan', 'xue', 'xun', 'ya', 'yan', 'yang',
      'yao', 'ye', 'yi', 'yin', 'ying', 'yo', 'yong', 'you', 'yu', 'yuan',
      'yue', 'yun', 'za', 'zai', 'zan', 'zang', 'zao', 'ze', 'zei', 'zen',
      'zeng', 'zha', 'zhai', 'zhan', 'zhang', 'zhao', 'zhe', 'zhen', 'zheng',
      'zhi', 'zhong', 'zhou', 'zhu', 'zhua', 'zhuai', 'zhuan', 'zhuang',
      'zhui', 'zhun', 'zhuo', 'zi', 'zong', 'zou', 'zu', 'zuan', 'zui', 'zun',
      'zuo',
    ]);
    loaded = true;
    loadMillis = sw.elapsedMilliseconds;
  }

  Map<String, int> get _mru {
    final m = <String, int>{};
    if (!AppState.ready) return m;
    final list = AppState.I.learnedWords;
    for (var i = 0; i < list.length; i++) {
      m[list[i]] = i;
    }
    return m;
  }

  Set<String> get _blacklist =>
      AppState.ready ? AppState.I.deletedWords.toSet() : <String>{};

  // -------------------------------------------------------------------------
  // Query
  // -------------------------------------------------------------------------
  List<Cand> query(
    String raw, {
    String mode = 'pinyin26',
    int limit = 48,
    bool fuzzy = false,
    List<String> fuzzyInitials = const [],
    List<String> fuzzyFinals = const [],
    List<String> fuzzySyllables = const [],
    bool wubiMix = true,
  }) {
    final sw = Stopwatch()..start();
    var input = raw.toLowerCase().replaceAll("'", '').replaceAll(' ', '');
    if (input.isEmpty) return const [];
    final cacheKey = '$mode|$input|$fuzzy|${fuzzyInitials.join(",")}|${fuzzyFinals.join(",")}|${fuzzySyllables.join(",")}|$wubiMix';
    final cached = _queryCache[cacheKey];
    if (cached != null) {
      lastQueryMicros = sw.elapsedMicroseconds;
      return cached.take(limit).toList();
    }

    List<Cand> result;
    switch (mode) {
      case 'wubi':
        result = _wubiQuery(input, mix: wubiMix, limit: limit);
        break;
      case 'shuangpin':
        final decoded = decodeShuangpin(input, AppState.ready ? AppState.I.shuangpinScheme : '小鹤双拼');
        input = decoded;
        result = _pinyinQuery(
          input,
          limit: limit,
          fuzzy: fuzzy,
          fuzzyInitials: fuzzyInitials,
          fuzzyFinals: fuzzyFinals,
          fuzzySyllables: fuzzySyllables,
        );
        break;
      case 'pinyin9':
        result = _t9Query(input, limit: limit);
        break;
      default:
        result = _pinyinQuery(
          input,
          limit: limit,
          fuzzy: fuzzy,
          fuzzyInitials: fuzzyInitials,
          fuzzyFinals: fuzzyFinals,
          fuzzySyllables: fuzzySyllables,
        );
    }
    lastQuery = input;
    _queryCache[cacheKey] = result;
    if (_queryCache.length > 160) _queryCache.remove(_queryCache.keys.first);
    lastQueryMicros = sw.elapsedMicroseconds;
    return result.take(limit).toList();
  }

  List<Cand> _pinyinQuery(
    String input, {
    required int limit,
    required bool fuzzy,
    required List<String> fuzzyInitials,
    required List<String> fuzzyFinals,
    required List<String> fuzzySyllables,
  }) {
    final out = <String, Cand>{};
    final mru = _mru;
    final black = _blacklist;
    final variants = fuzzy
        ? _fuzzyVariants(input, fuzzyInitials, fuzzyFinals, fuzzySyllables)
        : <String>{input};
    for (final q in variants) {
      _collectPinyin(q, out, mru, black, fuzzy && q != input ? 0.94 : 1.0);
      if (out.length > limit * 6) break;
    }

    // Personal lexicon has absolute priority.
    if (AppState.ready) {
      for (final row in AppState.I.lexicon) {
        final w = (row['w'] ?? '').toString();
        final p = (row['p'] ?? '').toString().replaceAll(' ', '').toLowerCase();
        if (w.isEmpty) continue;
        final match = p.startsWith(input) || p.isEmpty || w.startsWith(input);
        if (match) {
          out[w] = Cand(w, p, 1e15, '个人词库');
        }
      }
    }

    var list = out.values.toList()..sort((a, b) => b.score.compareTo(a.score));
    if (list.length < 10 && input.length >= 3) {
      final combos = _comboCandidates(input, mru);
      for (final c in combos) {
        if (!out.containsKey(c.text)) list.add(c);
      }
      list = list.take(limit).toList()..sort((a, b) => b.score.compareTo(a.score));
    }
    return list.take(limit).toList();
  }

  void _collectPinyin(
    String q,
    Map<String, Cand> out,
    Map<String, int> mru,
    Set<String> black,
    double weight,
  ) {
    // Full pinyin prefix via binary search on the sorted index.
    var lo = 0;
    var hi = _sorted.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (_sorted[mid].flat.compareTo(q) < 0) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    var checked = 0;
    for (var i = lo; i < _sorted.length && checked < 800; i++) {
      final e = _sorted[i];
      if (!e.flat.startsWith(q)) break;
      checked++;
      if (black.contains(e.w)) continue;
      final exact = e.flat == q;
      final lengthPenalty = 1.0 / (1.0 + max(0, e.flat.length - q.length) * 0.035);
      final lenBonus = 1.0 + (e.w.length - 1) * 0.06;
      final mruBoost = mru.containsKey(e.w) ? 1.0 + 3.0 / (1 + mru[e.w]!) : 1.0;
      final score = e.f * lenBonus * lengthPenalty * mruBoost *
          (exact ? 2.6 : 1.0) * weight;
      final prev = out[e.w];
      if (prev == null || score > prev.score) {
        out[e.w] = Cand(e.w, e.p, score, exact ? '全拼' : '前缀');
      }
    }

    // Initials (简拼) exact lookup.
    final initials = _byInitials[q];
    if (initials != null) {
      for (var i = 0; i < initials.length && i < 80; i++) {
        final e = initials[i];
        if (black.contains(e.w)) continue;
        final mruBoost = mru.containsKey(e.w) ? 1.0 + 3.0 / (1 + mru[e.w]!) : 1.0;
        final score = e.f * (1.0 + (e.w.length - 1) * 0.1) * mruBoost * 1.25 * weight;
        final prev = out[e.w];
        if (prev == null || score > prev.score) {
          out[e.w] = Cand(e.w, e.p, score, '简拼');
        }
      }
    }
  }

  List<Cand> _comboCandidates(String input, Map<String, int> mru) {
    final segs = segmentPinyin(input);
    if (segs.length < 2) return const [];
    final pools = <List<DictEntry>>[];
    for (final s in segs.take(3)) {
      final pool = (_singleBySyllable[s] ?? const <DictEntry>[])
          .where((e) => e.f > 1000)
          .take(3)
          .toList();
      if (pool.isEmpty) return const [];
      pools.add(pool);
    }
    final out = <Cand>[];
    void walk(int i, String acc, double score, String pinyin) {
      if (out.length >= 9) return;
      if (i == pools.length) {
        out.add(Cand(acc, pinyin, score, '单字组合'));
        return;
      }
      for (final e in pools[i]) {
        walk(i + 1, acc + e.w, score + e.f, '$pinyin ${e.p}');
      }
    }
    final base = segs.fold<double>(1e5, (p, s) => p * 0.5);
    walk(0, '', base, '');
    return out;
  }

  /// Greedy longest-match syllable segmentation with backtracking, used for
  /// building single-character combination candidates.
  List<String> segmentPinyin(String input) {
    final memo = <int, List<String>?>{};
    List<String>? solve(int i) {
      if (i == input.length) return <String>[];
      if (memo.containsKey(i)) return memo[i];
      String? best;
      List<String>? bestRest;
      for (final len in const [6, 5, 4, 3, 2, 1]) {
        if (i + len > input.length) continue;
        final s = input.substring(i, i + len);
        if (_syllables.contains(s)) {
          final rest = solve(i + len);
          if (rest != null) {
            if (best == null || s.length > best.length) {
              best = s;
              bestRest = rest;
            }
          }
        }
      }
      final res = best == null ? null : <String>[best, ...bestRest!];
      memo[i] = res;
      return res;
    }
    return solve(0) ?? const [];
  }

  List<Cand> _t9Query(String digits, {required int limit}) {
    final cached = _t9Cache[digits];
    if (cached != null) return cached.take(limit).toList();
    final mru = _mru;
    final black = _blacklist;
    final list = <DictEntry>[];
    final step = _entries.length > 30000 ? 1 : 1;
    for (var i = 0; i < _entries.length; i += step) {
      final e = _entries[i];
      if (e.t9.startsWith(digits)) {
        if (black.contains(e.w)) continue;
        list.add(e);
        if (list.length > 1200) break;
      }
    }
    list.sort((a, b) {
      final am = mru.containsKey(a.w) ? 4.0 : 1.0;
      final bm = mru.containsKey(b.w) ? 4.0 : 1.0;
      return (b.f * bm).compareTo(a.f * am);
    });
    final out = <Cand>[];
    for (final e in list) {
      final mruBoost = mru.containsKey(e.w) ? 1.0 + 3.0 / (1 + mru[e.w]!) : 1.0;
      out.add(Cand(e.w, e.p, e.f * mruBoost, 'T9'));
      if (out.length >= 120) break;
    }
    _t9Cache[digits] = out;
    if (_t9Cache.length > 80) _t9Cache.remove(_t9Cache.keys.first);
    return out.take(limit).toList();
  }

  Set<String> _fuzzyVariants(
    String q,
    List<String> initials,
    List<String> finals,
    List<String> syllables,
  ) {
    final out = <String>{q};
    final pairs = <List<String>>[];
    if (initials.contains('z_zh')) pairs.add(['zh', 'z']);
    if (initials.contains('c_ch')) pairs.add(['ch', 'c']);
    if (initials.contains('s_sh')) pairs.add(['sh', 's']);
    if (initials.contains('f_h')) pairs.add(['f', 'h']);
    if (initials.contains('n_l')) pairs.add(['n', 'l']);
    if (initials.contains('r_l')) pairs.add(['r', 'l']);
    if (finals.contains('an_ang')) pairs.add(['ang', 'an']);
    if (finals.contains('en_eng')) pairs.add(['eng', 'en']);
    if (finals.contains('in_ing')) pairs.add(['ing', 'in']);
    if (finals.contains('ian_iang')) pairs.add(['iang', 'ian']);
    if (finals.contains('uan_uang')) pairs.add(['uang', 'uan']);
    if (finals.contains('un_ong')) pairs.add(['ong', 'un']);
    if (finals.contains('eng_ong')) pairs.add(['ong', 'eng']);
    if (finals.contains('ai_ei')) pairs.add(['ai', 'ei']);
    if (finals.contains('ou_uo')) pairs.add(['uo', 'ou']);
    if (syllables.contains('hui_fei')) pairs.add(['hui', 'fei']);
    if (syllables.contains('huang_wang')) pairs.add(['huang', 'wang']);
    // Mutate copies; cap total variants to keep query latency bounded.
    for (final pair in pairs) {
      final current = out.toList();
      for (final s in current) {
        if (out.length >= 24) break;
        if (s.contains(pair[0])) {
          out.add(s.replaceFirst(pair[0], pair[1]));
        }
        if (s.contains(pair[1])) {
          out.add(s.replaceFirst(pair[1], pair[0]));
        }
      }
    }
    return out;
  }

  // -------------------------------------------------------------------------
  // Wubi 86 (demonstration table; see README for coverage)
  // -------------------------------------------------------------------------
  static const wubiTable = <List<String>>[
    ['trnt', '我'], ['wqiy', '你'], ['wqvb', '你好'], ['vbg', '好'], ['khk', '中'],
    ['lgyi', '国'], ['jghu', '是'], ['rqyy', '的'], ['ggll', '一'], ['def', '有'],
    ['tkg', '和'], ['dhfd', '在'], ['wwww', '人'], ['dddd', '大'], ['hhgg', '上'],
    ['ghi', '下'], ['gii', '不'], ['bnh', '了'], ['ypi', '这'], ['whj', '个'],
    ['wun', '们'], ['goi', '来'], ['gcf', '到'], ['jfy', '时'], ['svf', '要'],
    ['yidn', '就'], ['skd', '可'], ['nywy', '以'], ['yukq', '说'], ['rhfk', '年'],
    ['tjgf', '得'], ['bnhn', '也'], ['wbn', '他'], ['vbn', '她'], ['pxb', '它'],
    ['trwu', '我们'], ['wqwu', '你们'], ['vkg', '如'], ['fcu', '去'], ['fhw', '真'],
    ['shn', '想'], ['ngd', '发'], ['gki', '事'], ['dwi', '春'], ['fghy', '天'],
    ['ihi', '小'], ['mqi', '风'], ['iycy', '注'], ['puv', '实'], ['ynn', '词'],
    ['yng', '词'], ['fnu', '场'], ['tty', '笑'], ['kfcl', '吃'], ['qaj', '错'],
    ['wyg', '证'], ['eiu', '水'], ['ooo', '火'], ['ssss', '木'], ['hhhh', '目'],
    ['tttt', '禾'], ['nnnn', '已'], ['llll', '田'], ['pppp', '之'],
    ['rrrr', '白'], ['uuuu', '立'], ['vvvv', '女'], ['xxxx', '纟'],
    ['bbbb', '子'], ['cccc', '又'], ['mmmm', '山'], ['qqqq', '金'],
    ['ffff', '土'], ['dddd', '大'], ['iiii', '水'], ['aaaa', '工'],
    ['sgd', '本'], ['fcu', '去'], ['wfh', '会'], ['gma', '现'],
  ];

  List<Cand> _wubiQuery(String input, {required bool mix, required int limit}) {
    final out = <Cand>[];
    for (final row in wubiTable) {
      final code = row[0];
      if (code.startsWith(input)) {
        out.add(Cand(row[1], code, 1e9 / (1 + (code.length - input.length)) , '五笔'));
      }
    }
    if (AppState.ready) {
      for (final row in AppState.I.lexicon) {
        final w = (row['w'] ?? '').toString();
        if (w.startsWith(input) && w.isNotEmpty) {
          out.add(Cand(w, input, 1e12, '个人词库'));
        }
      }
    }
    if (out.isEmpty && mix) {
      return _pinyinQuery(
        input,
        limit: limit,
        fuzzy: false,
        fuzzyInitials: const [],
        fuzzyFinals: const [],
        fuzzySyllables: const [],
      );
    }
    out.sort((a, b) => b.score.compareTo(a.score));
    return out.take(limit).toList();
  }

  // -------------------------------------------------------------------------
  // Shuangpin decoding
  // -------------------------------------------------------------------------
  static const _xiaoheFinals = <String, List<String>>{
    'q': ['iu'], 'w': ['ei'], 'e': ['e'], 'r': ['uan', 'er'], 't': ['ue', 've'],
    'y': ['un'], 'u': ['u'], 'i': ['i'], 'o': ['uo', 'o'], 'p': ['ie'],
    'a': ['a'], 's': ['ong', 'iong'], 'd': ['ai'], 'f': ['en'], 'g': ['eng'],
    'h': ['ang'], 'j': ['an'], 'k': ['ing', 'uai'], 'l': ['iang', 'uang'],
    'z': ['ou'], 'x': ['ia', 'ua'], 'c': ['ao'], 'v': ['v', 'ui'], 'b': ['in'],
    'n': ['iao'], 'm': ['ian'],
  };

  static const _ziranmaFinals = <String, List<String>>{
    'q': ['iu'], 'w': ['ua', 'ia'], 'e': ['e'], 'r': ['uan', 'er'], 't': ['ue'],
    'y': ['uai', 'ing'], 'u': ['u'], 'i': ['i'], 'o': ['o', 'uo'], 'p': ['un'],
    'a': ['a'], 's': ['iong', 'ong'], 'd': ['uang', 'iang'], 'f': ['en', 'eng'],
    'g': ['eng'], 'h': ['ang'], 'j': ['an'], 'k': ['ao'], 'l': ['ai'],
    'z': ['ei'], 'x': ['ie'], 'c': ['iao'], 'v': ['v', 'ui'], 'b': ['ou'],
    'n': ['in'], 'm': ['ian'],
  };

  static const _initialMap = <String, String>{
    'b': 'b', 'c': 'c', 'd': 'd', 'f': 'f', 'g': 'g', 'h': 'h', 'j': 'j',
    'k': 'k', 'l': 'l', 'm': 'm', 'n': 'n', 'p': 'p', 'q': 'q', 'r': 'r',
    's': 's', 't': 't', 'w': 'w', 'x': 'x', 'y': 'y', 'z': 'z',
    'v': 'zh', 'i': 'ch', 'u': 'sh',
  };

  String decodeShuangpin(String input, String scheme) {
    final finals = scheme == '自然码双拼' ? _ziranmaFinals : _xiaoheFinals;
    final out = <String>[];
    var i = 0;
    while (i < input.length) {
      if (i == input.length - 1) {
        out.add(input[i]);
        break;
      }
      final a = input[i];
      final b = input[i + 1];
      String? syllable;
      final isInitial = _initialMap.containsKey(a);
      final fs = finals[b] ?? const <String>[];
      if (isInitial) {
        final init = _initialMap[a]!;
        for (final f in fs) {
          final s = init + f;
          if (_syllables.contains(s)) {
            syllable = s;
            break;
          }
        }
        syllable ??= init + (fs.isNotEmpty ? fs.first : b);
      } else {
        // Zero-initial: try the first letter as a final key first.
        final zfs = finals[a] ?? const <String>[];
        for (final f in zfs) {
          if (_syllables.contains(f)) {
            syllable = f;
            break;
          }
        }
        if (syllable == null) {
          for (final f in fs) {
            if (_syllables.contains(f)) {
              syllable = f;
              break;
            }
          }
        }
        syllable ??= (zfs.isNotEmpty ? zfs.first : a) + b;
      }
      out.add(syllable);
      i += 2;
    }
    return out.join();
  }

  /// Text/component search used by the handwriting lookup panel.
  List<Cand> textSearch(String raw, {int limit = 40}) {
    final q = raw.trim().toLowerCase();
    if (q.isEmpty) return const [];
    if (RegExp(r"^[a-z0-9\']+$").hasMatch(q)) {
      return query(q, limit: limit);
    }
    final out = _entries
        .where((e) => e.w.contains(q))
        .map((e) => Cand(e.w, e.p, e.f.toDouble(), '部件/文字'))
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return out.take(limit).toList();
  }

  // -------------------------------------------------------------------------
  // Associations / predictions
  // -------------------------------------------------------------------------
  static const associations = <String, List<String>>{
    '你好': ['吗', '呀', '世界', '我是'],
    '谢谢': ['你', '啦', '大家的支持'],
    '豆包': ['输入法', '很好用', 'AI 助手'],
    '输入法': ['复刻版', '设置', '键盘'],
    '好的': ['没问题', '谢谢', '收到'],
    '收到': ['谢谢', '马上处理', '明白'],
    '今天': ['天气', '下午', '开会'],
    '时间': ['安排', '地点', '确认'],
    '我们': ['一起', '明天', '开始'],
    '可以': ['的', '吗', '试试'],
  };

  List<String> associates(String word) {
    final out = <String>[];
    final direct = associations[word];
    if (direct != null) out.addAll(direct);
    if (AppState.ready) {
      for (final p in AppState.I.phrases) {
        final t = (p['text'] ?? '').toString();
        if (t.startsWith(word) && t != word) out.add(t);
        if (out.length >= 6) break;
      }
    }
    return out.take(6).toList();
  }

  static const emojiPredictions = <String, List<String>>{
    '你好': ['😊', '👋', '🤝'],
    '谢谢': ['🙏', '❤️', '😊'],
    '好的': ['👌', '✅', '👍'],
    '收到': ['👌', '📩', '✅'],
    '开心': ['😄', '🎉', '😁'],
    '难过': ['😢', '💔', '🥺'],
    '吃饭': ['🍚', '🍜', '😋'],
    '天气': ['☀️', '🌧️', '🌈'],
    '工作': ['💼', '💻', '📊'],
    '爱你': ['❤️', '😘', '💕'],
  };

  List<String> emojiFor(String word) {
    final direct = emojiPredictions[word];
    if (direct != null) return direct;
    return const ['😊', '👍', '🎉'];
  }

  static const stickers = <List<String>>[
    ['🐱', '猫猫点赞'], ['🐶', '狗狗开心'], ['🐼', '熊猫吃竹'], ['🦊', '狐狸眨眼'],
    ['🐰', '兔兔比心'], ['🐻', '小熊抱抱'], ['🐸', '青蛙大笑'], ['🐵', '猴子鼓掌'],
    ['🌻', '向日葵'], ['🍉', '西瓜'], ['☕', '咖啡'], ['🎈', '气球'],
  ];

  static const kaomoji = <String>[
    '(・ω・)ノ', '(＾▽＾)', '(￣▽￣)', '(´･ω･`)', '(๑•̀ㅂ•́)و✧',
    '(╯°□°）╯︵ ┻━┻', '┬─┬ ノ( ゜-゜ノ)', '(｡♥‿♥｡)', '(¬‿¬)',
    '(=^･ω･^=)', 'ヽ(•‿•)ノ', '(づ｡◕‿‿◕｡)づ', '(ง •̀_•́)ง', '(•̀ᴗ•́)و',
  ];
}
