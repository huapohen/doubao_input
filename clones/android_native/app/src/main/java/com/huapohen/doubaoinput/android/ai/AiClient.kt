package com.huapohen.doubaoinput.android.ai

import com.huapohen.doubaoinput.android.core.Prefs
import com.huapohen.doubaoinput.android.engine.TranslateData
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull
import org.json.JSONArray
import org.json.JSONObject
import java.io.BufferedReader
import java.net.HttpURLConnection
import java.net.SocketTimeoutException
import java.net.URL
import java.net.UnknownHostException

/**
 * OpenAI-compatible chat client (DeepSeek by default) plus rule-based offline fallbacks.
 * The API key is only ever read from Prefs / an optional build-time injection and is never logged.
 */
object AiClient {
    data class AiResult(
        val ok: Boolean,
        val text: String,
        val error: String = "",
        val offline: Boolean = false,
        val status: Int = 0
    )

    enum class Action(val label: String, val prompt: String) {
        BLESSING("写祝福", "请写一段真诚、温暖的中文祝福语，80字以内，不要解释。"),
        SOCIAL("高赞动态", "请写一条适合发在社交平台的中文动态，口语化、有画面感，80字以内。"),
        COMMENT("写评论", "请写一条自然、有共鸣的中文评论，40字以内。"),
        INTRO("自我介绍", "请写一段简洁自信的中文自我介绍，120字以内。"),
        INVITATION("宴席邀请", "请写一段得体、热情的中文宴席邀请，100字以内。"),
        EMAIL("写邮件", "请写一封结构清晰、礼貌的中文邮件，包含称呼、正文与结尾。"),
        COPYWRITING("爆款文案", "请写一段有传播力的中文产品文案，包含一句钩子与一句行动号召，100字以内。"),
        REWRITE("重写润色", "请把用户提供的文字改写得更通顺自然，保留原意，只输出改写结果。"),
        SUMMARY("总结", "请用一两句话总结用户提供的文字，只输出总结。"),
        KEYPOINTS("关键点", "请提取用户文字的关键点，用短句分条列出，只输出结果。"),
        LIST("列成列表", "请把用户文字整理为清晰的分条列表，只输出结果。"),
        CHECK("检查", "请检查用户文字中的错别字与语病，指出问题并给出修改后的句子。"),
        CHAT("聊天助手", "你是聊天回复助手。根据上下文给出3条简短自然的中文回复候选，每行一条。"),
        ORGANIZE("智能整理", "请整理用户提供的口语化文字：删除口水词、补全标点、分段，只输出整理后的文本。"),
        TRANSLATE("翻译", "请翻译用户提供的文本。中文译成英文，英文译成中文，只输出译文。")
    }

    fun localOrganize(text: String): String {
        var t = text.trim()
        if (t.isEmpty()) return ""
        val fillers = listOf("嗯", "呃", "额", "那个", "就是说", "然后呢", "就是", "这个这个", "呃嗯")
        fillers.forEach { t = t.replace(it, "") }
        t = t.replace(Regex("[ \\t]{2,}"), " ")
        t = t.replace(Regex("\\s*\\n\\s*"), "\n")
        // Add punctuation at line ends where missing.
        val lines = t.split("\n").map { line ->
            var s = line.trim()
            if (s.isNotEmpty() && s.last() !in "。！？!?；;，,、：:…." && !s.endsWith("”")) {
                s += "。"
            }
            s
        }
        t = lines.joinToString("\n")
        t = t.replace("，。", "。").replace("。。", "。").replace("，！", "！").replace("，？", "？")
        return t
    }

    fun localCorrect(text: String): String {
        var t = text
        val fixes = mapOf(
            "在再" to "再", "已后" to "以后", "因该" to "应该", "以经" to "已经", "忘想" to "妄想",
            "的的" to "的", "了了" to "了", "我我" to "我", "你你" to "你",
            "做为" to "作为", "即然" to "既然", "按装" to "安装", "登入" to "登录"
        )
        fixes.forEach { (bad, good) -> t = t.replace(bad, good) }
        t = t.replace(Regex("\\s+([，。！？；：])"), "$1")
        t = t.replace(Regex("([，。！？；：])\\s+"), "$1")
        if (t.isNotBlank() && t.last() !in "。！？!?….") t += "。"
        return t
    }

    fun localWrite(action: Action, topic: String): String {
        val t = topic.trim()
        return when (action) {
            Action.BLESSING -> "愿你所求皆如愿，所行化坦途。${if (t.isNotBlank()) "祝你$t，" else ""}平安顺遂，万事胜意！"
            Action.SOCIAL -> if (t.isNotBlank()) "$t\n\n生活明朗，万物可爱。把这份好心情分享给你 ✨" else "生活明朗，万物可爱。今天也想把这份好心情分享给你 ✨"
            Action.COMMENT -> if (t.isNotBlank()) "关于「$t」，说得太对了，学到了！👍" else "说得太对了，学到了！👍"
            Action.INTRO -> "你好，我是${t.ifBlank { "一名热爱学习与分享的工程师" }}。平时喜欢研究产品与效率工具，很高兴认识你，期待一起交流成长。"
            Action.INVITATION -> "诚挚邀请您参加${t.ifBlank { "我们的聚会" }}，期待与您相聚，共度一段轻松愉快的时光。具体时间地点稍后同步，敬请光临。"
            Action.EMAIL -> "您好：\n\n关于${t.ifBlank { "近期事项" }}，现向您同步如下：目前进展顺利，我们会在完成后第一时间告知您。\n\n如有疑问，欢迎随时联系。\n\n此致\n敬礼"
            Action.COPYWRITING -> "把复杂留给自己，把简单交给你。${t.ifBlank { "每一次输入" }}，都更顺手一点。现在就来试试吧。"
            Action.REWRITE -> if (t.isBlank()) "请先输入需要润色的文字。" else localOrganize(t)
            Action.SUMMARY -> {
                if (t.isBlank()) "请先输入需要总结的文字。"
                else {
                    val first = t.split(Regex("[。！？!?\\n]")).firstOrNull { it.isNotBlank() }?.trim() ?: t.take(40)
                    "要点：$first。"
                }
            }
            Action.KEYPOINTS -> {
                if (t.isBlank()) "请先输入文字。" else t.split(Regex("[。！？!?\\n；;]"))
                    .map { it.trim() }.filter { it.isNotEmpty() }.take(6)
                    .mapIndexed { i, s -> "${i + 1}. $s" }.joinToString("\n")
            }
            Action.LIST -> {
                if (t.isBlank()) "请先输入文字。" else t.split(Regex("[。！？!?\\n；;]"))
                    .map { it.trim() }.filter { it.isNotEmpty() }.take(8)
                    .joinToString("\n") { "• $it" }
            }
            Action.CHECK -> if (t.isBlank()) "请先输入需要检查的文字。" else localCorrect(t)
            Action.CHAT -> {
                val base = if (t.isNotBlank()) "收到，关于「${t.take(12)}」" else "收到"
                listOf("$base，我看一下哈～", "好的没问题，稍后回复你。", "哈哈确实，我也这么觉得。").joinToString("\n")
            }
            Action.ORGANIZE -> localOrganize(t)
            Action.TRANSLATE -> localTranslate(t)
        }
    }

    fun localTranslate(text: String): String {
        val t = text.trim()
        if (t.isEmpty()) return ""
        val zh = Regex("[\\u4e00-\\u9fff]").containsMatchIn(t)
        return TranslateData.translate(t, zh)
    }

    suspend fun generate(action: Action, input: String, extraContext: String = ""): AiResult {
        if (!Prefs.smartMode) {
            return AiResult(false, offlineFallback(action, input), "当前为基础输入模式，已使用离线结果。", offline = true)
        }
        val key = Prefs.aiKey()
        if (key.isBlank()) {
            return AiResult(false, offlineFallback(action, input), "未配置 API Key，已使用离线结果。", offline = true)
        }
        if (!Prefs.aiEnabled) {
            return AiResult(false, offlineFallback(action, input), "AI 服务已关闭，已使用离线结果。", offline = true)
        }
        val result = chat(key, action, input, extraContext)
        if (!result.ok && result.text.isNotBlank()) return result
        return result
    }

    fun offlineFallback(action: Action, input: String): String = when (action) {
        Action.ORGANIZE -> localOrganize(input)
        Action.TRANSLATE -> localTranslate(input)
        Action.CHECK -> localCorrect(input)
        Action.REWRITE -> localOrganize(input)
        Action.SUMMARY, Action.KEYPOINTS, Action.LIST -> localWrite(action, input)
        else -> localWrite(action, input)
    }

    private suspend fun chat(key: String, action: Action, input: String, extraContext: String): AiResult {
        val base = Prefs.aiBaseUrl.trim().trimEnd('/')
        val model = Prefs.aiModel.trim().ifBlank { "deepseek-chat" }
        val body = JSONObject().apply {
            put("model", model)
            put("stream", false)
            put("temperature", if (action == Action.CHECK || action == Action.TRANSLATE) 0.2 else 0.8)
            put("max_tokens", 800)
            put("messages", JSONArray().apply {
                put(JSONObject().put("role", "system").put("content", systemPrompt(action)))
                if (extraContext.isNotBlank()) {
                    put(JSONObject().put("role", "system").put("content", "上下文（仅供理解，不要直接复述）：\n$extraContext"))
                }
                put(JSONObject().put("role", "user").put("content", input.ifBlank { "请自由发挥。" }))
            })
        }
        return withContext(Dispatchers.IO) {
            var conn: HttpURLConnection? = null
            try {
                val url = URL("$base/chat/completions")
                conn = (url.openConnection() as HttpURLConnection).apply {
                    requestMethod = "POST"
                    connectTimeout = 20_000
                    readTimeout = 20_000
                    doOutput = true
                    setRequestProperty("Content-Type", "application/json; charset=utf-8")
                    setRequestProperty("Authorization", "Bearer $key")
                    setRequestProperty("Accept", "application/json")
                }
                conn.outputStream.use { it.write(body.toString().toByteArray(Charsets.UTF_8)) }
                val code = conn.responseCode
                if (code in 200..299) {
                    val text = conn.inputStream.bufferedReader().use(BufferedReader::readText)
                    val obj = JSONObject(text)
                    val content = obj.optJSONArray("choices")?.optJSONObject(0)
                        ?.optJSONObject("message")?.optString("content")?.trim().orEmpty()
                    if (content.isBlank()) {
                        AiResult(false, offlineFallback(action, input), "AI 返回内容为空，已使用离线结果。", offline = true, status = code)
                    } else {
                        AiResult(true, content, status = code)
                    }
                } else {
                    val errText = try {
                        conn.errorStream?.bufferedReader()?.use(BufferedReader::readText).orEmpty()
                    } catch (t: Throwable) { "" }
                    val msg = when (code) {
                        401 -> "API Key 无效（401），请到 AI 服务设置检查。"
                        402 -> "账户额度不足（402），请充值后重试。"
                        403 -> "请求被拒绝（403），请检查 Key 权限。"
                        429 -> "请求过于频繁（429），请稍后重试。"
                        in 500..599 -> "AI 服务暂时不可用（$code），请稍后重试。"
                        else -> "请求失败（$code）${if (errText.isNotBlank()) "：${errText.take(120)}" else ""}"
                    }
                    AiResult(false, offlineFallback(action, input), "$msg 已使用离线结果。", offline = true, status = code)
                }
            } catch (e: UnknownHostException) {
                AiResult(false, offlineFallback(action, input), "无法连接 AI 服务，请检查网络或 Base URL。已使用离线结果。", offline = true)
            } catch (e: SocketTimeoutException) {
                AiResult(false, offlineFallback(action, input), "请求超时（20 秒），请重试。已使用离线结果。", offline = true)
            } catch (e: Throwable) {
                AiResult(false, offlineFallback(action, input), "请求失败：${e.javaClass.simpleName}。已使用离线结果。", offline = true)
            } finally {
                conn?.disconnect()
            }
        }
    }

    private fun systemPrompt(action: Action): String = action.prompt +
        " 使用简体中文（翻译任务按目标语言）。不要使用 Markdown 代码块，不要输出思考过程。"

    suspend fun testConnection(): AiResult {
        val key = Prefs.aiKey()
        if (key.isBlank()) return AiResult(false, "", "未配置 API Key。")
        val base = Prefs.aiBaseUrl.trim().trimEnd('/')
        val model = Prefs.aiModel.trim().ifBlank { "deepseek-chat" }
        val body = JSONObject().apply {
            put("model", model)
            put("stream", false)
            put("max_tokens", 16)
            put("messages", JSONArray().put(JSONObject().put("role", "user").put("content", "回复 OK")))
        }
        return withContext(Dispatchers.IO) {
            var conn: HttpURLConnection? = null
            try {
                conn = (URL("$base/chat/completions").openConnection() as HttpURLConnection).apply {
                    requestMethod = "POST"
                    connectTimeout = 12_000
                    readTimeout = 12_000
                    doOutput = true
                    setRequestProperty("Content-Type", "application/json; charset=utf-8")
                    setRequestProperty("Authorization", "Bearer $key")
                }
                conn.outputStream.use { it.write(body.toString().toByteArray(Charsets.UTF_8)) }
                val code = conn.responseCode
                if (code in 200..299) {
                    AiResult(true, "连接成功（HTTP $code）", status = code)
                } else {
                    val msg = when (code) {
                        401 -> "API Key 无效（401）"
                        402 -> "额度不足（402）"
                        429 -> "请求过于频繁（429）"
                        in 500..599 -> "服务端错误（$code）"
                        else -> "连接失败（HTTP $code）"
                    }
                    AiResult(false, "", msg, status = code)
                }
            } catch (e: Throwable) {
                AiResult(false, "", "连接失败：${e.javaClass.simpleName}", offline = true)
            } finally {
                conn?.disconnect()
            }
        }
    }
}
