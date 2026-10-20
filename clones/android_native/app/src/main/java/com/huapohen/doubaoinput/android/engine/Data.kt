package com.huapohen.doubaoinput.android.engine

object TranslateData {
    // Original, hand-written common-phrase table used for offline translation.
    private val raw = """
        你好|hello
        您好|hello
        谢谢|thank you
        谢谢你|thank you
        不客气|you're welcome
        对不起|sorry
        没关系|it's okay
        再见|goodbye
        早上好|good morning
        晚上好|good evening
        晚安|good night
        请|please
        是的|yes
        不是|no
        好的|okay
        可以|can
        不可以|cannot
        我|I
        你|you
        他|he
        她|she
        我们|we
        你们|you
        他们|they
        爱|love
        喜欢|like
        想要|want
        需要|need
        知道|know
        觉得|think
        认为|believe
        可以吗|is it okay
        多少钱|how much
        在哪里|where is it
        什么时候|when
        为什么|why
        怎么办|what should I do
        什么|what
        谁|who
        哪里|where
        怎么|how
        今天|today
        明天|tomorrow
        昨天|yesterday
        现在|now
        时间|time
        分钟|minute
        小时|hour
        天|day
        星期|week
        月|month
        年|year
        早上|morning
        中午|noon
        下午|afternoon
        晚上|evening
        吃饭|eat
        喝水|drink water
        睡觉|sleep
        工作|work
        学习|study
        开会|meeting
        加班|work overtime
        下班|get off work
        上班|go to work
        回家|go home
        出发|set off
        到达|arrive
        手机|phone
        电脑|computer
        键盘|keyboard
        输入法|input method
        输入|input
        打字|type
        语音|voice
        文字|text
        翻译|translate
        设置|settings
        剪贴板|clipboard
        表情|emoji
        常用语|quick phrases
        词库|dictionary
        主题|theme
        深色模式|dark mode
        浅色模式|light mode
        键盘高度|keyboard height
        单手模式|one-hand mode
        悬浮键盘|floating keyboard
        麦克风|microphone
        权限|permission
        网络|network
        离线|offline
        在线|online
        AI 写作|AI writing
        智能整理|smart organize
        人工智能|artificial intelligence
        模型|model
        接口|API
        密钥|API key
        测试|test
        成功|success
        失败|failed
        重试|retry
        复制|copy
        粘贴|paste
        删除|delete
        清空|clear
        保存|save
        取消|cancel
        确定|confirm
        返回|back
        完成|done
        搜索|search
        发送|send
        接收|receive
        消息|message
        通知|notification
        账号|account
        登录|log in
        退出|log out
        同步|sync
        数据|data
        隐私|privacy
        安全|security
        帮助|help
        反馈|feedback
        关于|about
        版本|version
        更新|update
        下载|download
        安装|install
        欢迎|welcome
        恭喜|congratulations
        生日快乐|happy birthday
        新年快乐|happy new year
        节日快乐|happy holiday
        加油|keep going
        辛苦了|thanks for your hard work
        没问题|no problem
        当然|of course
        可能|maybe
        一定|definitely
        马上|right away
        稍等|wait a moment
        请问|excuse me
        名字|name
        地址|address
        电话|telephone
        邮箱|email
        公司|company
        学校|school
        医院|hospital
        餐厅|restaurant
        酒店|hotel
        机场|airport
        车站|station
        地铁|subway
        公交|bus
        火车|train
        飞机|airplane
        打车|take a taxi
        走路|walk
        左转|turn left
        右转|turn right
        直走|go straight
        附近|nearby
        远|far
        近|near
        大|big
        小|small
        多|many
        少|few
        好|good
        坏|bad
        快|fast
        慢|slow
        热|hot
        冷|cold
        开心|happy
        难过|sad
        累|tired
        饿|hungry
        渴|thirsty
        漂亮|beautiful
        有趣|interesting
        重要|important
        简单|simple
        复杂|complex
        免费|free
        付款|pay
        价格|price
        钱|money
        人民币|RMB
        美元|USD
        文件|file
        图片|image
        视频|video
        音乐|music
        电影|movie
        游戏|game
        新闻|news
        天气|weather
        下雨|rain
        下雪|snow
        晴天|sunny
        阴天|cloudy
        风|wind
        太阳|sun
        月亮|moon
        星星|star
        北京|Beijing
        上海|Shanghai
        广州|Guangzhou
        深圳|Shenzhen
        中国|China
        美国|United States
        英国|United Kingdom
        日本|Japan
        韩国|Korea
        法国|France
        德国|Germany
        加拿大|Canada
        澳大利亚|Australia
        中文|Chinese
        英文|English
        语言|language
        朋友|friend
        家人|family
        同事|colleague
        老师|teacher
        学生|student
        医生|doctor
        工程师|engineer
        设计师|designer
        产品经理|product manager
        经理|manager
        老板|boss
        客户|customer
        今天天气很好|the weather is nice today
        很高兴认识你|nice to meet you
        请稍等一下|please wait a moment
        我马上回来|I'll be right back
        我不太明白|I don't quite understand
        可以再说一遍吗|could you say that again
        这个多少钱|how much is this
        我想去机场|I want to go to the airport
        请问洗手间在哪里|where is the restroom
        祝你今天愉快|have a nice day
        收到，谢谢|received, thank you
        好的，没问题|okay, no problem
        我们明天见|see you tomorrow
        会议改到下午三点|the meeting is moved to 3 pm
        请把文件发给我|please send me the file
        正在处理中|processing
        已经完成|completed
        需要我帮忙吗|do you need help
        这是我们的新版本|this is our new version
        欢迎使用豆包输入法|welcome to Doubao Input
        语音输入很方便|voice input is convenient
        离线也能打字|you can type offline
        支持中文和英文|supports Chinese and English
    """.trimIndent()

    private val zhToEn = LinkedHashMap<String, String>()
    private val enToZh = LinkedHashMap<String, String>()

    init {
        raw.lineSequence().forEach { line ->
            val idx = line.indexOf('|')
            if (idx > 0) {
                val zh = line.substring(0, idx).trim()
                val en = line.substring(idx + 1).trim()
                if (zh.isNotEmpty() && en.isNotEmpty()) {
                    zhToEn[zh] = en
                    enToZh.putIfAbsent(en.lowercase(), zh)
                }
            }
        }
    }

    fun size(): Int = zhToEn.size

    fun zhToEn(text: String): String {
        val t = text.trim()
        if (t.isEmpty()) return ""
        zhToEn[t]?.let { return it }
        // Longest-phrase replacement over the table.
        var out = t
        val keys = zhToEn.keys.sortedByDescending { it.length }
        var replaced = false
        for (k in keys) {
            if (k.length >= 2 && out.contains(k)) {
                out = out.replace(k, " ${zhToEn[k]} ")
                replaced = true
            }
        }
        if (replaced) return out.replace(Regex("\\s+"), " ").trim()
        // Character-level fallback for the most common single characters.
        val chars = StringBuilder()
        for (c in t) {
            val s = c.toString()
            if (zhToEn.containsKey(s)) {
                chars.append(zhToEn[s]).append(' ')
                replaced = true
            } else if (c.isWhitespace()) {
                chars.append(c)
            } else {
                chars.append(s)
            }
        }
        return if (replaced) chars.toString().trim() else ""
    }

    fun enToZh(text: String): String {
        val t = text.trim().lowercase()
        if (t.isEmpty()) return ""
        enToZh[t]?.let { return it }
        val keys = enToZh.keys.sortedByDescending { it.length }
        var out = t
        var replaced = false
        for (k in keys) {
            if (k.length >= 3 && Regex("(^|\\W)${Regex.escape(k)}(\\W|$)").containsMatchIn(out)) {
                out = out.replace(Regex("(^|\\W)${Regex.escape(k)}(\\W|$)"), "$1${enToZh[k]}$2")
                replaced = true
            }
        }
        if (!replaced) {
            enToZh[t]?.let { return it }
        }
        return if (replaced) out.replace(Regex("\\s+"), " ").trim() else ""
    }

    fun translate(text: String, zhToEn: Boolean): String {
        val result = if (zhToEn) zhToEn(text) else enToZh(text)
        return result.ifBlank { "" }
    }
}

object TradData {
    private val pairs = """
        爱愛 罢罷 备備 贝貝 笔筆 毕畢 边邊 变變 标標 表錶 别別 宾賓 补補 参參 产產 长長
        尝嘗 车車 彻徹 陈陳 称稱 尘塵 处處 传傳 从從 达達 带帶 单單 当當 党黨 导導 灯燈 邓鄧
        敌敵 点點 电電 东東 动動 读讀 断斷 对對 队隊 儿兒 发發 范範 飞飛 丰豐 风風 复複 个個
        广廣 归歸 国國 过過 还還 汉漢 号號 后後 划劃 华華 画畫 怀懷 坏壞 欢歡 环環 换換 会會
        击擊 机機 积積 极極 几幾 继繼 家傢 价價 艰艱 见見 将將 讲講 奖獎 节節 结結 进進 举舉
        觉覺 开開 课課 来來 乐樂 离離 里裡 礼禮 两兩 辆輛 疗療 辽遼 临臨 刘劉 龙龍 楼樓 陆陸
        录錄 虑慮 论論 马馬 买買 卖賣 满滿 门門 梦夢 面麵 灭滅 难難 鸟鳥 宁寧 农農 齐齊 气氣
        钱錢 浅淺 亲親 轻輕 庆慶 穷窮 区區 权權 劝勸 让讓 热熱 认認 荣榮 萨薩 赛賽 扫掃 杀殺
        设設 谁誰 审審 声聲 胜勝 师師 时時 实實 识識 势勢 视視 试試 书書 术術 树樹 帅帥 双雙
        说說 岁歲 孙孫 台臺 态態 谈談 叹嘆 汤湯 讨討 题題 体體 条條 铁鐵 听聽 厅廳 头頭 图圖
        团團 万萬 网網 为為 卫衛 温溫 闻聞 问問 无無 务務 雾霧 习習 细細 虾蝦 显顯 现現 线線
        乡鄉 响響 写寫 谢謝 兴興 选選 学學 寻尋 亚亞 严嚴 颜顏 阳陽 样樣 药藥 爷爺 业業 叶葉
        页頁 义義 议議 艺藝 亿億 忆憶 应應 优優 邮郵 犹猶 鱼魚 与與 语語 预預 园園 员員 圆圓
        远遠 愿願 云雲 运運 杂雜 灾災 赞贊 脏臟 择擇 则則 泽澤 赠贈 张張 涨漲 帐帳 赵趙 这這
        针針 征徵 挣掙 郑鄭 证證 织織 职職 执執 纸紙 致緻 制製 质質 终終 种種 众眾 周週 轴軸
        昼晝 烛燭 筑築 庄莊 装裝 壮壯 状狀 准準 浊濁 总總 钻鑽 韩韓 吴吳 吕呂 卢盧 叶葉 号號
        才纔 干乾 干幹 系係 系繫 只隻 只祇 台檯 台颱 发髮 松鬆 谷穀 划劃 了瞭 制製 表錶 种種
        虫蟲 争爭 网網 无無 万萬 与與 丑醜 丰豐 仆僕 斗鬥 云雲 后後 历歷 历曆 占佔 汇匯 汇彙
    """.trimIndent().split(Regex("\\s+")).filter { it.length >= 2 }

    private val s2t = HashMap<Char, Char>()
    private val t2s = HashMap<Char, Char>()
    private val phraseS2T = linkedMapOf(
        "软件" to "軟件", "硬件" to "硬件", "鼠标" to "鼠標", "键盘" to "鍵盤", "输入法" to "輸入法",
        "输入" to "輸入", "语音" to "語音", "设置" to "設定", "剪贴板" to "剪貼簿", "词库" to "詞庫",
        "常用语" to "常用語", "主题" to "主題", "网络" to "網絡", "账号" to "賬號", "登录" to "登錄",
        "数据" to "數據", "信息" to "信息", "隐私" to "隱私", "权限" to "權限", "翻译" to "翻譯",
        "智能" to "智能", "整理" to "整理", "写作" to "寫作", "桌面" to "桌面", "电脑" to "電腦",
        "手机" to "手機", "平板" to "平板", "屏幕" to "屏幕", "功能" to "功能", "系统" to "系統",
        "现在" to "現在", "问题" to "問題", "时间" to "時間", "开始" to "開始", "结束" to "結束",
        "完成" to "完成", "谢谢" to "謝謝", "再见" to "再見", "对不起" to "對不起", "没关系" to "沒關係"
    )
    private val phraseT2S = phraseS2T.entries.associate { (k, v) -> v to k }

    init {
        pairs.forEach { p ->
            if (p.length >= 2) {
                val s = p[0]; val t = p[1]
                if (s != t) { s2t.putIfAbsent(s, t); t2s.putIfAbsent(t, s) }
            }
        }
    }

    fun toTraditional(text: String): String {
        var out = text
        phraseS2T.forEach { (s, t) -> out = out.replace(s, t) }
        val sb = StringBuilder(out.length)
        out.forEach { c -> sb.append(s2t[c] ?: c) }
        return sb.toString()
    }

    fun toSimplified(text: String): String {
        var out = text
        phraseT2S.forEach { (t, s) -> out = out.replace(t, s) }
        val sb = StringBuilder(out.length)
        out.forEach { c -> sb.append(t2s[c] ?: c) }
        return sb.toString()
    }

    fun mappingCount(): Int = s2t.size
}

object WubiData {
    private val raw = """
        trnt 我
        wqiy 你
        wqvb 你好
        vbg 好
        rqyy 的
        jghu 是
        g 一
        dhfd 在
        gii 不
        bnh 了
        def 有
        tkg 和
        wwww 人
        khk 中
        khlg 中国
        lgyi 国
        dddd 大
        ihty 小
        hhgg 上
        ghi 下
        gdi 天
        fbn 地
        goi 来
        fcu 去
        wbn 他
        vbn 她
        pxb 它
        wu 们
        kcg 吗
        knx 呢
        ypi 这
        vfb 那
        yukq 说
        ytdg 话
        ygeg 请
        ytmt 谢
        ytyt 谢谢
        cfy 对
        wfcu 会
        ce 能
        skd 可
        nywy 以
        s 要
        shnu 想
        rhf 看
        krh 听
        pghg 写
        pbf 字
        rsh 打
        jnv 电
        eyb 脑
        jney 电脑
        rtgh 手
        smn 机
        rtsm 手机
        qvte 键盘
        lwty 输入
        ifcy 法
        ipbf 学
        tgd 生
        jfy 时
        ujf 间
        jfuj 时间
        wynb 今天
        jeg 明
        jjjj 日
        eeee 月
        rhfk 年
        ktn 吃
        kjqn 喝
        htgf 睡
        ipmq 觉
        fhn 起
        ysi 床
        khtk 路
        lgnh 车
        nui 飞
        fnrt 场
        ux 北
        yiu 京
        fmuf 南
        aii 东
        sghg 西
        dwj 春
        dhtu 夏
        toi 秋
        tuu 冬
        mqi 风
        fghy 雨
        fv 雪
        fcu 云
        mmm 山
        iiii 水
        oooo 火
        ssss 木
        qqqq 金
        ffff 土
        gggg 王
        vvvv 女
        bbbb 子
        pegt 家
        eeg 朋
        dc 友
        eedc 朋友
        epdc 爱
        nyny 心
        gkvh 事
        ngeg 情
        aaaa 工
        wthf 作
        wcng 公司
        khyy 中文
        gmft 再见
        jhhh 早上
        jqhh 晚上
        gmw 现在
        jgjg 问题
        thfn 怎么
        wftc 什么
        kvfb 哪里
        wywt 为什么
        skny 可以
        fkcq 喜欢
        tduc 知道
        ipef 觉得
        fdsw 需要
        dteg 帮助
        frrf 支持
        iqu 学习
        awth 工作
        tgit 生活
        anlw 世界
        ftjg 老师
        iptg 学生
        atg 医生
        ygeg 谢谢
        yt 谢
        wq 你
        vb 好
        kh 中
        lg 国
        tr 我
        rq 的
        jg 是
        dh 在
        de 有
    """.trimIndent()

    private val entries: List<Pair<String, String>> by lazy {
        raw.lineSequence().mapNotNull { line ->
            val p = line.trim().split(Regex("\\s+"))
            if (p.size >= 2 && p[0].isNotEmpty()) p[0] to p[1] else null
        }.distinctBy { it.first + it.second }.toList()
    }

    fun size(): Int = entries.size

    fun lookup(code: String, limit: Int = 20): List<Pair<String, String>> {
        if (code.isBlank()) return emptyList()
        val prefix = code.lowercase()
        val exact = entries.filter { it.first == prefix }
        val starts = entries.filter { it.first.startsWith(prefix) && it.first != prefix }
        val sorted = (exact + starts.sortedBy { it.first.length })
        return sorted.distinctBy { it.second }.take(limit)
    }

    fun hintFor(code: String): String = lookup(code, 1).firstOrNull()?.first ?: ""
}

object StrokeData {
    // h=横 s=竖 p=撇 n=捺/点 z=折. Demo table (~35 characters).
    private val raw = """
        h 一
        hh 二
        hhh 三
        hs 十
        hsh 土
        hsh 工
        hhhs 王
        hspn 木
        hspnh 本
        shh 上
        hsn 下
        pn 人
        pn 八
        pn 入
        hpn 大
        hhpn 天
        shh 口
        szhh 日
        szhhh 目
        szhs 田
        szhs 中
        szhhshn 国
        szs 山
        zph 女
        zsh 子
        zphzsh 好
        spn 小
        szpn 水
        nppn 火
        pshz 我
        pzsn 你
        hhp 干
        hhs 士
        hzh 己
        hzhh 已
        hzzh 巴
    """.trimIndent()

    private val entries: List<Pair<String, String>> by lazy {
        raw.lineSequence().mapNotNull { line ->
            val p = line.trim().split(Regex("\\s+"))
            if (p.size >= 2) p[0] to p[1] else null
        }.distinctBy { it.first + it.second }.toList()
    }

    fun size(): Int = entries.size

    fun lookup(strokes: String): List<String> {
        val s = strokes.lowercase().replace("_", "z")
        if (s.isBlank()) return emptyList()
        if (!s.contains('?')) {
            return entries.filter { it.first.startsWith(s) }.map { it.second }.distinct()
        }
        val pattern = StringBuilder("^")
        s.forEach { c -> if (c == '?') pattern.append('.') else pattern.append(Regex.escape(c.toString())) }
        val regex = Regex(pattern.toString())
        return entries.filter { regex.containsMatchIn(it.first) }.map { it.second }.distinct().take(20)
    }
}

/**
 * Lightweight template recognizer for the handwriting demo. It is intentionally a demo:
 * it scores simple shape features (stroke count, dominant directions, closed loops, aspect)
 * against ~30 templates, and the handwriting panel also exposes pinyin lookup ("手写找字")
 * for real dictionary coverage.
 */
object HandwritingRecognizer {
    data class Template(
        val ch: String, val strokes: Int, val horizontal: Double, val vertical: Double,
        val diagonal: Double, val closed: Double, val aspect: Double
    )

    private val templates = listOf(
        Template("一", 1, 1.0, 0.0, 0.0, 0.0, 3.5),
        Template("二", 2, 1.0, 0.0, 0.0, 0.0, 2.6),
        Template("三", 3, 1.0, 0.0, 0.0, 0.0, 2.2),
        Template("十", 2, 0.55, 0.45, 0.0, 0.0, 1.4),
        Template("人", 2, 0.0, 0.0, 1.0, 0.0, 0.9),
        Template("八", 2, 0.0, 0.0, 1.0, 0.0, 1.3),
        Template("入", 2, 0.0, 0.0, 1.0, 0.0, 0.8),
        Template("大", 3, 0.4, 0.05, 0.55, 0.0, 1.1),
        Template("小", 3, 0.05, 0.4, 0.55, 0.0, 1.2),
        Template("口", 3, 0.55, 0.45, 0.0, 1.0, 1.0),
        Template("日", 4, 0.62, 0.38, 0.0, 1.0, 0.85),
        Template("目", 5, 0.65, 0.35, 0.0, 1.0, 0.7),
        Template("田", 5, 0.55, 0.4, 0.05, 1.0, 1.0),
        Template("中", 4, 0.35, 0.65, 0.0, 0.6, 0.9),
        Template("上", 3, 0.6, 0.4, 0.0, 0.0, 1.1),
        Template("下", 3, 0.55, 0.25, 0.2, 0.0, 1.1),
        Template("土", 3, 0.7, 0.3, 0.0, 0.0, 1.4),
        Template("王", 4, 0.75, 0.25, 0.0, 0.0, 1.5),
        Template("工", 3, 0.75, 0.25, 0.0, 0.0, 1.7),
        Template("山", 3, 0.25, 0.75, 0.0, 0.0, 1.3),
        Template("女", 3, 0.3, 0.1, 0.6, 0.0, 0.9),
        Template("子", 3, 0.4, 0.35, 0.25, 0.0, 0.9),
        Template("我", 7, 0.25, 0.2, 0.55, 0.0, 1.0),
        Template("你", 7, 0.2, 0.45, 0.35, 0.0, 0.8),
        Template("好", 6, 0.3, 0.3, 0.4, 0.0, 1.2),
        Template("木", 4, 0.5, 0.25, 0.25, 0.0, 1.1),
        Template("本", 5, 0.6, 0.2, 0.2, 0.0, 1.1),
        Template("水", 4, 0.2, 0.4, 0.4, 0.0, 1.0),
        Template("火", 4, 0.1, 0.2, 0.7, 0.0, 0.9),
        Template("0", 1, 0.0, 0.0, 1.0, 0.9, 0.95),
        Template("1", 1, 0.0, 1.0, 0.0, 0.0, 0.35),
        Template("2", 1, 0.6, 0.0, 0.4, 0.0, 0.8),
        Template("3", 1, 0.3, 0.0, 0.7, 0.2, 0.7),
        Template("8", 1, 0.0, 0.0, 1.0, 0.6, 0.7)
    )

    data class Stroke(val points: List<Pair<Float, Float>>)
    data class Result(val ch: String, val score: Double)

    fun recognize(strokes: List<Stroke>): List<Result> {
        if (strokes.isEmpty()) return emptyList()
        val pts = strokes.flatMap { it.points }
        if (pts.size < 4) return emptyList()
        val minX = pts.minOf { it.first }; val maxX = pts.maxOf { it.first }
        val minY = pts.minOf { it.second }; val maxY = pts.maxOf { it.second }
        val w = (maxX - minX).coerceAtLeast(1f)
        val h = (maxY - minY).coerceAtLeast(1f)
        var horizontal = 0.0; var vertical = 0.0; var diagonal = 0.0
        var closed = 0.0
        for (s in strokes) {
            if (s.points.size < 2) continue
            val a = s.points.first(); val b = s.points.last()
            val dx = kotlin.math.abs(b.first - a.first) / w
            val dy = kotlin.math.abs(b.second - a.second) / h
            if (dx > dy * 2) horizontal += 1.0 else if (dy > dx * 2) vertical += 1.0 else diagonal += 1.0
            val dist = kotlin.math.hypot((b.first - a.first).toDouble(), (b.second - a.second).toDouble())
            val box = kotlin.math.hypot((maxX - minX).toDouble(), (maxY - minY).toDouble())
            if (dist < box * 0.16) closed += 1.0
        }
        val total = horizontal + vertical + diagonal + 0.0001
        val aspect = (w / h).toDouble()
        val vector = doubleArrayOf(
            strokes.size.toDouble(),
            horizontal / total, vertical / total, diagonal / total,
            closed.coerceAtMost(1.0), aspect
        )
        val results = templates.map { t ->
            val target = doubleArrayOf(
                t.strokes.toDouble(), t.horizontal, t.vertical, t.diagonal, t.closed, t.aspect
            )
            var dist = 0.0
            dist += kotlin.math.abs(vector[0] - target[0]) / 3.0
            dist += kotlin.math.abs(vector[1] - target[1]) * 1.2
            dist += kotlin.math.abs(vector[2] - target[2]) * 1.2
            dist += kotlin.math.abs(vector[3] - target[3]) * 1.0
            dist += kotlin.math.abs(vector[4] - target[4]) * 0.8
            dist += kotlin.math.abs(kotlin.math.ln((vector[5].coerceAtLeast(0.2))) - kotlin.math.ln((target[5].coerceAtLeast(0.2)))) * 0.35
            Result(t.ch, dist)
        }.sortedBy { it.score }
        return results.take(6).filter { it.score < 1.55 }.ifEmpty { results.take(3) }
    }
}
