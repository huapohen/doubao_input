import 'dart:math';

// ---------------------------------------------------------------------------
// Traditional / simplified conversion (demonstration mapping)
// ---------------------------------------------------------------------------
const _s2tPairs = <String, String>{
  '汉': '漢', '语': '語', '输': '輸', '法': '法', '这': '這', '个': '個',
  '们': '們', '来': '來', '时': '時', '说': '說', '会': '會', '对': '對',
  '开': '開', '关': '關', '门': '門', '问': '問', '题': '題', '记': '記',
  '设': '設', '置': '置', '键': '鍵', '盘': '盤', '买': '買', '卖': '賣',
  '车': '車', '马': '馬', '鸟': '鳥', '鱼': '魚', '龙': '龍', '凤': '鳳',
  '爱': '愛', '恋': '戀', '见': '見', '觉': '覺', '学': '學', '习': '習',
  '书': '書', '写': '寫', '读': '讀', '听': '聽', '声': '聲', '音': '音',
  '识': '識', '别': '別', '词': '詞', '库': '庫', '云': '雲', '网': '網',
  '络': '絡', '电': '電', '话': '話', '视': '視', '频': '頻', '图': '圖',
  '片': '片', '软': '軟', '件': '件', '应': '應', '用': '用', '数': '數',
  '据': '據', '传': '傳', '统': '統', '权': '權', '限': '限', '私': '私',
  '护': '護', '协': '協', '议': '議', '户': '戶', '账': '賬', '号': '號',
  '登': '登', '录': '錄', '退': '退', '出': '出', '发': '發', '现': '現',
  '实': '實', '际': '際', '经': '經', '验': '驗', '进': '進', '步': '步',
  '还': '還', '过': '過', '为': '為', '无': '無', '长': '長', '间': '間',
  '样': '樣', '点': '點', '击': '擊', '选': '選', '择': '擇', '换': '換',
  '变': '變', '态': '態', '风': '風', '格': '格', '欢': '歡', '乐': '樂',
  '兴': '興', '趣': '趣', '喜': '喜', '庆': '慶', '祝': '祝', '贺': '賀',
  '礼': '禮', '物': '物', '钱': '錢', '银': '銀', '行': '行', '员': '員',
  '团': '團', '队': '隊', '组': '組', '织': '織', '业': '業', '务': '務',
  '产': '產', '品': '品', '质': '質', '量': '量', '价': '價', '额': '額',
  '总': '總', '结': '結', '计': '計', '划': '劃', '简': '簡', '单': '單',
  '复': '復', '杂': '雜', '难': '難', '易': '易', '快': '快', '慢': '慢',
  '远': '遠', '近': '近', '边': '邊', '东': '東', '南': '南', '西': '西',
  '北': '北', '国': '國', '城': '城', '市': '市', '乡': '鄉', '村': '村',
  '县': '縣', '区': '區', '街': '街', '道': '道', '路': '路', '桥': '橋',
  '口': '口', '早': '早', '晚': '晚', '饭': '飯', '餐': '餐', '馆': '館',
  '茶': '茶', '酒': '酒', '店': '店', '热': '熱', '冷': '冷', '暖': '暖',
  '凉': '涼', '春': '春', '夏': '夏', '秋': '秋', '冬': '冬', '节': '節',
  '假': '假', '日': '日', '期': '期', '周': '週', '末': '末', '岁': '歲',
  '龄': '齡', '儿': '兒', '女': '女', '男': '男', '妈': '媽', '爸': '爸',
  '亲': '親', '友': '友', '师': '師', '生': '生', '医': '醫', '院': '院',
  '药': '藥', '病': '病', '健': '健', '康': '康', '运': '運', '动': '動',
  '跑': '跑', '游': '遊', '泳': '泳', '球': '球', '赛': '賽', '赢': '贏',
  '胜': '勝', '败': '敗', '战': '戰', '斗': '鬥', '军': '軍', '将': '將',
  '帅': '帥', '鹰': '鷹', '鸡': '雞', '鸭': '鴨', '鹅': '鵝', '猪': '豬',
  '猫': '貓', '狗': '狗', '虾': '蝦', '蟹': '蟹', '虫': '蟲', '蚁': '蟻',
  '树': '樹', '叶': '葉', '花': '花', '草': '草', '果': '果', '园': '園',
  '林': '林', '森': '森', '湖': '湖', '海': '海', '河': '河', '江': '江',
  '山': '山', '石': '石', '雨': '雨', '雪': '雪', '雷': '雷', '光': '光',
  '阳': '陽', '阴': '陰', '星': '星', '月': '月', '空': '空', '气': '氣',
  '温': '溫', '度': '度', '爽': '爽', '湿': '濕', '干': '乾', '净': '淨',
  '脏': '髒', '美': '美', '丑': '醜', '高': '高', '矮': '矮', '胖': '胖',
  '瘦': '瘦', '黑': '黑', '白': '白', '红': '紅', '蓝': '藍', '绿': '綠',
  '黄': '黃', '紫': '紫', '谁': '誰', '哪': '哪', '里': '裡', '么': '麼',
  '什': '什', '怎': '怎', '没': '沒', '系': '係', '联': '聯', '给': '給',
  '让': '讓', '从': '從', '向': '向', '往': '往', '跟': '跟', '与': '與',
  '及': '及', '或': '或', '但': '但', '是': '是', '而': '而', '且': '且',
  '因': '因', '所': '所', '以': '以', '如': '如', '虽': '雖', '然': '然',
  '却': '卻', '仍': '仍', '旧': '舊', '新': '新', '真': '真', '正': '正',
  '错': '錯', '误': '誤', '完': '完', '成': '成', '功': '功', '失': '失',
  '停': '停', '止': '止', '删': '刪', '除': '除', '清': '清', '添': '添',
  '加': '加', '编': '編', '辑': '輯', '保': '保', '存': '存', '取': '取',
  '消': '消', '确': '確', '认': '認', '恢': '恢', '默': '默', '更': '更',
  '改': '改', '查': '查', '看': '看', '找': '找', '到': '到', '搜': '搜',
  '索': '索', '翻': '翻', '页': '頁', '面': '面', '板': '板', '栏': '欄',
  '窗': '窗', '屏': '屏', '幕': '幕', '手': '手', '机': '機', '脑': '腦',
  '桌': '桌', '笔': '筆', '本': '本', '平': '平', '备': '備', '连': '連',
  '接': '接', '同': '同', '份': '份', '导': '導', '入': '入', '后': '後',
  '台': '台', '服': '服', '器': '器', '密': '密', '钥': '鑰', '匙': '匙',
  '安': '安', '全': '全', '证': '證', '码': '碼', '扫': '掃', '描': '描',
  '二': '二', '维': '維', '陆': '陸', '注': '註', '册': '冊', '帮': '幫',
  '助': '助', '反': '反', '馈': '饋', '意': '意', '建': '建', '答': '答',
  '常': '常', '谢': '謝', '请': '請', '迎': '迎', '再': '再', '次': '次',
  '临': '臨', '使': '使', '版': '版', '许': '許', '可': '可', '条': '條',
  '款': '款', '稳': '穩', '定': '定', '速': '速', '率': '率', '效': '效',
  '优': '優', '秀': '秀', '厉': '厲', '害': '害', '强': '強', '大': '大',
  '心': '心', '伤': '傷', '担': '擔', '忧': '憂', '希': '希', '望': '望',
  '梦': '夢', '想': '想', '目': '目', '标': '標', '方': '方', '线': '線',
  '决': '決', '惯': '慣', '规': '規', '则': '則',
};

String toTraditional(String input) {
  final b = StringBuffer();
  for (final ch in input.split('')) {
    b.write(_s2tPairs[ch] ?? ch);
  }
  return b.toString();
}

String toSimplified(String input) {
  final rev = <String, String>{};
  _s2tPairs.forEach((k, v) {
    if (!rev.containsKey(v)) rev[v] = k;
  });
  final b = StringBuffer();
  for (final ch in input.split('')) {
    b.write(rev[ch] ?? ch);
  }
  return b.toString();
}

String applyScript(String input, bool traditional) =>
    traditional ? toTraditional(input) : toSimplified(input);

// ---------------------------------------------------------------------------
// Offline translation dictionary
// ---------------------------------------------------------------------------
const _zhEn = <String, String>{
  '你好': 'hello', '早上好': 'good morning', '晚上好': 'good evening', '晚安': 'good night',
  '谢谢': 'thank you', '非常感谢': 'thank you very much', '不客气': 'you are welcome',
  '对不起': 'sorry', '没关系': 'it is okay', '再见': 'goodbye', '请': 'please',
  '是': 'yes', '不是': 'no', '好的': 'okay', '可以': 'can', '不可以': 'cannot',
  '我': 'I', '你': 'you', '他': 'he', '她': 'she', '我们': 'we', '你们': 'you',
  '喜欢': 'like', '爱': 'love', '想': 'want', '需要': 'need', '有': 'have',
  '没有': 'do not have', '知道': 'know', '不知道': 'do not know', '明白': 'understand',
  '今天': 'today', '明天': 'tomorrow', '昨天': 'yesterday', '现在': 'now', '时间': 'time',
  '工作': 'work', '学习': 'study', '开会': 'meeting', '会议': 'meeting', '项目': 'project',
  '完成': 'finish', '开始': 'start', '结束': 'end', '问题': 'problem', '解决': 'solve',
  '帮助': 'help', '支持': 'support', '确认': 'confirm', '收到': 'received', '发送': 'send',
  '消息': 'message', '电话': 'phone', '邮件': 'email', '地址': 'address', '公司': 'company',
  '客户': 'client', '产品': 'product', '服务': 'service', '质量': 'quality', '价格': 'price',
  '输入法': 'input method', '键盘': 'keyboard', '语音': 'voice', '文字': 'text', '翻译': 'translation',
  '智能': 'smart', '联想': 'association', '设置': 'settings', '剪贴板': 'clipboard',
  '常用语': 'quick phrases', '表情': 'emoji', '手写': 'handwriting', '双拼': 'double pinyin',
  '五笔': 'wubi', '词库': 'lexicon', '权限': 'permission', '隐私': 'privacy', '模式': 'mode',
  '云端': 'cloud', '离线': 'offline', '网络': 'network', '连接': 'connect', '失败': 'failed',
  '成功': 'success', '测试': 'test', '版本': 'version', '更新': 'update', '关于': 'about',
  '首页': 'home', '返回': 'back', '删除': 'delete', '添加': 'add', '编辑': 'edit', '保存': 'save',
  '取消': 'cancel', '确定': 'confirm', '清空': 'clear', '复制': 'copy', '粘贴': 'paste',
  '替换': 'replace', '重试': 'retry', '上一条': 'previous', '下一条': 'next',
  '天气': 'weather', '吃饭': 'eat', '咖啡': 'coffee', '会议时间': 'meeting time',
  '地点': 'location', '北京': 'Beijing', '上海': 'Shanghai', '中国': 'China',
  '朋友': 'friend', '家人': 'family', '同事': 'colleague', '老师': 'teacher', '学生': 'student',
  '医院': 'hospital', '学校': 'school', '机场': 'airport', '酒店': 'hotel', '餐厅': 'restaurant',
  '手机': 'phone', '电脑': 'computer', '平板': 'tablet', '应用': 'app', '软件': 'software',
  '数据': 'data', '账号': 'account', '登录': 'log in', '退出': 'log out', '同步': 'sync',
  '超级互传': 'super transfer', '设备': 'device', '二维码': 'QR code', '扫描': 'scan',
  '欢迎': 'welcome', '使用': 'use', '功能': 'feature', '体验': 'experience', '演示': 'demo',
};

const _enZh = <String, String>{
  'hello': '你好', 'hi': '你好', 'good morning': '早上好', 'good evening': '晚上好',
  'good night': '晚安', 'thank you': '谢谢', 'thanks': '谢谢', 'you are welcome': '不客气',
  'sorry': '对不起', 'goodbye': '再见', 'bye': '再见', 'please': '请', 'yes': '是',
  'no': '不是', 'okay': '好的', 'ok': '好的', 'i': '我', 'you': '你', 'he': '他',
  'she': '她', 'we': '我们', 'they': '他们', 'love': '爱', 'like': '喜欢', 'want': '想',
  'need': '需要', 'have': '有', 'know': '知道', 'understand': '明白', 'today': '今天',
  'tomorrow': '明天', 'yesterday': '昨天', 'now': '现在', 'time': '时间', 'work': '工作',
  'study': '学习', 'meeting': '会议', 'project': '项目', 'finish': '完成', 'start': '开始',
  'end': '结束', 'problem': '问题', 'solve': '解决', 'help': '帮助', 'support': '支持',
  'confirm': '确认', 'received': '收到', 'send': '发送', 'message': '消息', 'phone': '电话',
  'email': '邮件', 'address': '地址', 'company': '公司', 'client': '客户', 'product': '产品',
  'service': '服务', 'quality': '质量', 'price': '价格', 'input method': '输入法',
  'keyboard': '键盘', 'voice': '语音', 'text': '文字', 'translation': '翻译', 'smart': '智能',
  'settings': '设置', 'clipboard': '剪贴板', 'emoji': '表情', 'handwriting': '手写',
  'lexicon': '词库', 'permission': '权限', 'privacy': '隐私', 'mode': '模式', 'cloud': '云端',
  'offline': '离线', 'network': '网络', 'connect': '连接', 'failed': '失败', 'success': '成功',
  'test': '测试', 'version': '版本', 'update': '更新', 'about': '关于', 'home': '首页',
  'back': '返回', 'delete': '删除', 'add': '添加', 'edit': '编辑', 'save': '保存',
  'cancel': '取消', 'clear': '清空', 'copy': '复制', 'paste': '粘贴', 'replace': '替换',
  'retry': '重试', 'weather': '天气', 'coffee': '咖啡', 'location': '地点', 'Beijing': '北京',
  'Shanghai': '上海', 'China': '中国', 'friend': '朋友', 'family': '家人', 'teacher': '老师',
  'student': '学生', 'hospital': '医院', 'school': '学校', 'airport': '机场', 'hotel': '酒店',
  'restaurant': '餐厅', 'computer': '电脑', 'tablet': '平板', 'app': '应用', 'software': '软件',
  'data': '数据', 'account': '账号', 'sync': '同步', 'device': '设备', 'scan': '扫描',
  'welcome': '欢迎', 'feature': '功能', 'demo': '演示', 'meeting time': '会议时间',
};

String localTranslate(String input, {required bool toEnglish}) {
  if (input.trim().isEmpty) return '';
  final text = input.trim();
  if (toEnglish) {
    final keys = _zhEn.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
    final b = StringBuffer();
    var i = 0;
    while (i < text.length) {
      var matched = false;
      for (final k in keys) {
        if (text.startsWith(k, i)) {
          if (b.isNotEmpty && !b.toString().endsWith(' ')) b.write(' ');
          b.write(_zhEn[k]);
          i += k.length;
          matched = true;
          break;
        }
      }
      if (!matched) {
        final ch = text[i];
        if (RegExp(r'[\s，。！？、；：,.!?;:]').hasMatch(ch)) {
          if (b.isNotEmpty && !b.toString().endsWith(' ')) b.write(' ');
        } else {
          b.write(ch);
        }
        i++;
      }
    }
    return b.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }
  final words = text.split(RegExp(r'\s+'));
  final b = StringBuffer();
  var i = 0;
  while (i < words.length) {
    var matched = false;
    for (var len = min(3, words.length - i); len >= 1; len--) {
      final phrase = words.sublist(i, i + len).join(' ');
      final key = phrase.toLowerCase().replaceAll(RegExp(r'[.,!?;:]$'), '');
      if (_enZh.containsKey(key)) {
        b.write(_enZh[key]);
        i += len;
        matched = true;
        break;
      }
    }
    if (!matched) {
      b.write(words[i]);
      i++;
    }
  }
  return b.toString();
}

// ---------------------------------------------------------------------------
// Local smart organize
// ---------------------------------------------------------------------------
const _fillers = ['嗯', '啊', '呃', '额', '那个', '就是说', '然后呢', '怎么说呢'];

String localOrganize(
  String input, {
  bool aggressive = false,
  bool blankLine = false,
  String punctuation = '智能标点',
  String mode = '默认整理',
}) {
  var text = input.trim();
  if (text.isEmpty) return '';
  for (final f in _fillers) {
    text = text.replaceAll('$f，', '').replaceAll('$f,', '').replaceAll(f, '');
  }
  if (aggressive) {
    text = text
        .replaceAll('就是', '')
        .replaceAll('然后', '')
        .replaceAll(RegExp(r'\s+'), '');
  }
  text = text.replaceAll(RegExp(r'[，,]{2,}'), '，').replaceAll(RegExp(r'[。]{2,}'), '。');
  if (mode == '精简') {
    text = text.replaceAll('。', '，');
    text = text.replaceAll(RegExp(r'，+$'), '');
  }
  if (mode == '正式') {
    text = text
        .replaceAll('咋', '怎么')
        .replaceAll('啥', '什么')
        .replaceAll('挺', '很')
        .replaceAll('特别', '非常')
        .replaceAll('搞', '处理')
        .replaceAll('弄', '处理')
        .replaceAll('咱们', '我们');
  }
  if (punctuation == '不添加标点') {
    text = text.replaceAll(RegExp(r'[，。！？、；：]$'), '');
  } else if (punctuation == '逗号分隔') {
    text = text.replaceAll('。', '，');
    if (!text.endsWith('，')) text = '$text，';
  } else if (punctuation != '不添加标点' && !RegExp(r'[。！？.!?]$').hasMatch(text)) {
    text = '$text。';
  }
  if (blankLine) {
    text = text.replaceAll(RegExp(r'(?<=[。！？])'), '\n\n').trim();
  }
  return text;
}

String localRewrite(String text) {
  if (text.trim().isEmpty) return '';
  return text
      .replaceAll('很', '非常')
      .replaceAll('好', '出色')
      .replaceAll('不错', '令人满意')
      .replaceAll('我觉得', '我认为');
}

String localSummary(String text) {
  final parts = text.split(RegExp(r'[。！？\n]')).where((e) => e.trim().isNotEmpty).toList();
  if (parts.isEmpty) return '';
  if (parts.length == 1) return parts.first;
  return '${parts.first}。${parts.last}。';
}

String localKeyPoints(String text) {
  final parts = text.split(RegExp(r'[。！？\n；;]')).where((e) => e.trim().isNotEmpty).toList();
  return parts.take(5).map((e) => '• ${e.trim()}').join('\n');
}

String localList(String text) {
  final parts = text.split(RegExp(r'[。！？\n；;]')).where((e) => e.trim().isNotEmpty).toList();
  return parts.take(8).map((e) => '${parts.indexOf(e) + 1}. ${e.trim()}').join('\n');
}

String localCheck(String text) {
  final issues = <String>[];
  if (text.contains('  ')) issues.add('存在连续空格');
  if (RegExp(r'[，。]{2,}').hasMatch(text)) issues.add('存在重复标点');
  if (RegExp('[a-zA-Z]').hasMatch(text) && !RegExp(r'[a-zA-Z]\s').hasMatch(text)) {
    issues.add('中英文之间建议加空格');
  }
  if (text.trim().isEmpty) issues.add('文本为空');
  if (issues.isEmpty) return text;
  return '检查完成：${issues.join('；')}。\n\n建议文本：\n${text.trim()}';
}

const _blessingTemplates = [
  '愿你的每一天都被温柔以待，所遇皆美好，所求皆如愿。新的一岁，平安喜乐，万事顺意！',
  '把最真挚的祝福送给你：愿你眼里有光，心中有爱，脚下有路，未来可期。生日快乐！',
  '祝你前程似锦，岁岁平安；愿所有努力都有回报，所有期待都不被辜负。',
];

const _postTemplates = [
  '今天也有在认真生活。把喜欢的事做久一点，把重要的人放在心间。愿我们都能在自己的节奏里，慢慢变好。',
  '记录一下最近的小确幸：一杯好喝的咖啡、一段不被打扰的午后、一句恰到好处的问候。生活值得被认真对待。',
  '不必追赶别人的脚步，你自有你的花期。保持热爱，奔赴山海。',
];

const _commentTemplates = [
  '说得太对了，收藏起来慢慢看，感谢分享！',
  '这个角度很新颖，学到了，期待更多这样的内容。',
  '看完很有共鸣，尤其是最后一句，写出了很多人的心声。',
];

const _introTemplates = [
  '你好，我是[你的名字]，专注于[领域]与[方向]。喜欢用简单的方式解决复杂的问题，期待与你交流合作。',
  '你好，我是[你的名字]。一名[职业]，平时关注[兴趣领域]，希望在这里认识更多有趣的人。',
  '你好！我是一名热爱学习与分享的[职业]，擅长[技能]。保持好奇，持续输出。',
];

const _inviteTemplates = [
  '诚挚邀请您拨冗出席我们的宴席。届时略备薄酒，愿与您共叙情谊。时间：[日期] [时间]，地点：[地点]。期待您的到来！',
  '您好！我们诚挚邀请您参加[活动名称]，共度美好时光。时间：[日期]，地点：[地点]。静候光临，不胜荣幸。',
  '家有喜事，特备薄宴，诚邀您与家人一同前来分享喜悦。时间：[日期]，地点：[地点]。期待相聚！',
];

const _emailTemplates = [
  '您好：\n\n关于[事项]，现将相关情况说明如下：\n\n[正文]\n\n如有疑问，请随时与我联系。感谢您的支持与配合！\n\n此致\n敬礼\n[署名]',
  '尊敬的[收件人]：\n\n您好！\n\n[邮件正文]\n\n期待您的回复。祝工作顺利！\n\n[署名]\n[日期]',
  'Hi [Name],\n\nHope this message finds you well. I am writing to [purpose].\n\n[Details]\n\nLooking forward to your reply.\n\nBest regards,\n[Your name]',
];

const _viralTemplates = [
  '别再等了！这个让效率翻倍的方法，今天一次性讲清楚。看完记得收藏，关键时刻能救急。',
  '为什么别人总能轻松完成，而你却越忙越乱？答案可能就藏在这三个小习惯里。',
  '我用了一个月，终于找到最适合普通人的成长路径。没有鸡汤，全是可执行的方法。',
];

const _allTemplates = <String, List<String>>{
  '写祝福': _blessingTemplates,
  '高赞动态': _postTemplates,
  '写评论': _commentTemplates,
  '自我介绍': _introTemplates,
  '宴席邀请': _inviteTemplates,
  '写邮件': _emailTemplates,
  '爆款文案': _viralTemplates,
};

String localWrite(String action, String topic, {int variant = 0}) {
  final list = _allTemplates[action] ?? _postTemplates;
  var text = list[variant % list.length];
  final t = topic.trim();
  if (t.isNotEmpty) {
    text = text.replaceAll('[你的名字]', t).replaceAll('[Name]', t).replaceAll('[收件人]', t);
    if (action == '写祝福' || action == '写评论' || action == '高赞动态') {
      text = '$text\n\n—— 关于「$t」';
    }
  }
  return text;
}

List<String> localWriteVariants(String action, String topic) {
  final n = (_allTemplates[action] ?? _postTemplates).length;
  return List.generate(n, (i) => localWrite(action, topic, variant: i));
}

String localChatReply(String context) {
  final c = context;
  if (RegExp('你好|hi|hello|在吗').hasMatch(c)) return '你好呀！有什么可以帮你的～';
  if (RegExp('谢谢|感谢').hasMatch(c)) return '不客气，随时找我！';
  if (RegExp('时间|几点|会议').hasMatch(c)) return '我查一下日程，稍后把确认好的时间发你。';
  if (RegExp('地址|地点|哪里').hasMatch(c)) return '地址我整理好了：北京市海淀区示例路 1 号，到了给我发消息。';
  if (RegExp(r'\?|？').hasMatch(c)) return '这个问题我建议先拆成两步：明确目标，再列出可执行的动作。';
  return '收到，我看一下。稍后给你一个更完整的回复。';
}
