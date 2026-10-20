/// Five-stroke (笔画) demonstration table. Encoding: 1=横 2=竖 3=撇 4=点/捺 5=折.
/// Prefix search is used, so partial sequences yield candidates.
class StrokeCand {
  final String char;
  final String code;
  const StrokeCand(this.char, this.code);
}

const strokeTable = <List<String>>[
  ['一', '1'], ['二', '11'], ['三', '111'], ['十', '12'], ['人', '34'],
  ['大', '134'], ['小', '234'], ['口', '251'], ['日', '2511'], ['月', '3511'],
  ['上', '211'], ['下', '124'], ['中', '2512'], ['山', '252'], ['水', '2534'],
  ['火', '4334'], ['木', '1234'], ['手', '3112'], ['心', '4544'], ['天', '1134'],
  ['王', '1121'], ['女', '531'], ['子', '521'], ['好', '531521'], ['你', '3235234'],
  ['我', '3121534'], ['的', '32511354'], ['不', '1324'], ['了', '52'],
  ['是', '251112134'], ['在', '132121'], ['有', '132511'], ['和', '31234251'],
  ['这', '4134454'], ['个', '342'], ['们', '3225'], ['来', '1431234'],
  ['到', '154121'], ['时', '2511124'], ['要', '125221531'], ['就', '412512135'],
  ['可', '12512'], ['以', '5434'], ['说', '454325135'], ['年', '311212'],
  ['得', '3322511124'], ['也', '525'], ['他', '32525'], ['她', '531525'],
  ['它', '44535'], ['豆', '1251431'], ['包', '35515'], ['输', '152134125'],
  ['入', '34'], ['法', '44112154'], ['键', '3111251112'], ['盘', '33541425221'],
  ['智', '311342512511'], ['能', '5425113535'], ['联', '122111134'], ['想', '1234251114544'],
];

List<StrokeCand> lookupStrokes(String code, {int limit = 40}) {
  if (code.isEmpty) return const [];
  final exact = <StrokeCand>[];
  final prefix = <StrokeCand>[];
  for (final row in strokeTable) {
    final c = row[0];
    final s = row[1];
    if (s == code) {
      exact.add(StrokeCand(c, s));
    } else if (s.startsWith(code)) {
      prefix.add(StrokeCand(c, s));
    }
  }
  prefix.sort((a, b) => a.code.length.compareTo(b.code.length));
  return [...exact, ...prefix].take(limit).toList();
}

String describeStroke(String code) {
  const names = {'1': '横', '2': '竖', '3': '撇', '4': '点', '5': '折'};
  return code.split('').map((e) => names[e] ?? e).join(' ');
}
