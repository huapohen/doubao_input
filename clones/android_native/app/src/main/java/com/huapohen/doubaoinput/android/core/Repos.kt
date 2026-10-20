package com.huapohen.doubaoinput.android.core

import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID

data class Phrase(val id: String, val text: String, val category: String)

object PhraseRepo {
    private val defaults = listOf(
        "你好，请问有什么可以帮你？" to "问候",
        "好的，收到，谢谢！" to "工作",
        "稍等一下，我马上处理。" to "工作",
        "方便的时候回我一下～" to "工作",
        "辛苦了，早点休息。" to "问候",
        "生日快乐，愿你万事顺遂！" to "祝福",
        "新年快乐，阖家幸福！" to "祝福",
        "不好意思，我晚点到。" to "日常",
        "没问题，就这么定了。" to "工作",
        "地址：北京市海淀区中关村大街1号" to "地址",
        "手机号：138 0000 0000" to "信息",
        "感谢你的耐心等待。" to "客服"
    )

    fun all(): MutableList<Phrase> {
        val arr = Prefs.getJsonArray(Prefs.K_COMMON_PHRASES)
        val out = mutableListOf<Phrase>()
        for (i in 0 until arr.length()) {
            val o = arr.optJSONObject(i) ?: continue
            out.add(Phrase(o.optString("id"), o.optString("text"), o.optString("category", "常用")))
        }
        if (out.isEmpty()) {
            defaults.forEach { (t, c) -> out.add(Phrase(UUID.randomUUID().toString(), t, c)) }
            save(out)
        }
        return out
    }

    fun save(list: List<Phrase>) {
        val arr = JSONArray()
        list.forEach { p ->
            arr.put(JSONObject().put("id", p.id).put("text", p.text).put("category", p.category))
        }
        Prefs.putJson(Prefs.K_COMMON_PHRASES, arr)
    }

    fun add(text: String, category: String = "常用") { if (text.isBlank()) return; val l = all(); l.add(0, Phrase(UUID.randomUUID().toString(), text.trim(), category.ifBlank { "常用" })); save(l) }
    fun update(id: String, text: String, category: String) { val l = all(); val i = l.indexOfFirst { it.id == id }; if (i >= 0) { l[i] = l[i].copy(text = text.trim(), category = category.ifBlank { "常用" }); save(l) } }
    fun delete(id: String) { val l = all(); l.removeAll { it.id == id }; save(l) }
    fun categories(): List<String> = all().map { it.category }.distinct()
}

data class LexiconEntry(val word: String, val pinyin: String, val source: String = "个人")

object LexiconRepo {
    fun all(): MutableList<LexiconEntry> {
        val arr = Prefs.getJsonArray(Prefs.K_PERSONAL_LEXICON)
        val out = mutableListOf<LexiconEntry>()
        for (i in 0 until arr.length()) {
            val o = arr.optJSONObject(i) ?: continue
            out.add(LexiconEntry(o.optString("word"), o.optString("pinyin"), o.optString("source", "个人")))
        }
        return out
    }

    fun save(list: List<LexiconEntry>) {
        val arr = JSONArray()
        list.forEach { e -> arr.put(JSONObject().put("word", e.word).put("pinyin", e.pinyin).put("source", e.source)) }
        Prefs.putJson(Prefs.K_PERSONAL_LEXICON, arr)
    }

    fun add(word: String, pinyin: String, source: String = "个人"): Boolean {
        val w = word.trim(); if (w.isEmpty()) return false
        val l = all()
        if (l.any { it.word == w }) return false
        l.add(0, LexiconEntry(w, pinyin.trim().lowercase(), source))
        save(l); return true
    }

    fun update(oldWord: String, newWord: String, pinyin: String) {
        val l = all()
        val i = l.indexOfFirst { it.word == oldWord }
        if (i >= 0) {
            l[i] = l[i].copy(word = newWord.trim(), pinyin = pinyin.trim().lowercase())
            save(l)
        }
    }

    fun delete(word: String) { val l = all(); l.removeAll { it.word == word }; save(l) }
    fun clearPersonal() { save(all().filter { it.source != "个人" }) }
    fun clearAll() { save(emptyList()) }

    fun importContacts(names: List<String>): Int {
        var n = 0
        names.forEach { name ->
            if (add(name, "", "通讯录")) n++
        }
        return n
    }
}

data class ClipItem(val id: String, val text: String, val kind: String, val ts: Long, val pinned: Boolean = false)

object ClipboardRepo {
    private const val MAX = 100
    fun all(): MutableList<ClipItem> {
        val arr = Prefs.getJsonArray(Prefs.K_CLIPBOARD_ITEMS)
        val out = mutableListOf<ClipItem>()
        for (i in 0 until arr.length()) {
            val o = arr.optJSONObject(i) ?: continue
            out.add(ClipItem(o.optString("id"), o.optString("text"), o.optString("kind", "text"), o.optLong("ts"), o.optBoolean("pinned")))
        }
        return out
    }

    fun save(list: List<ClipItem>) {
        val arr = JSONArray()
        list.sortedWith(compareByDescending<ClipItem> { it.pinned }.thenByDescending { it.ts }).take(MAX).forEach { c ->
            arr.put(JSONObject().put("id", c.id).put("text", c.text).put("kind", c.kind).put("ts", c.ts).put("pinned", c.pinned))
        }
        Prefs.putJson(Prefs.K_CLIPBOARD_ITEMS, arr)
    }

    fun add(text: String, kind: String = "text"): ClipItem? {
        val t = text.trim()
        if (t.isEmpty()) return null
        val list = all()
        list.removeAll { it.text == t }
        val item = ClipItem(UUID.randomUUID().toString(), t, kind, System.currentTimeMillis())
        list.add(0, item)
        save(list)
        return item
    }

    fun delete(id: String) { val l = all(); l.removeAll { it.id == id }; save(l) }
    fun clear(keepPinned: Boolean = false) { save(if (keepPinned) all().filter { it.pinned } else emptyList()) }
    fun togglePin(id: String) { val l = all(); val i = l.indexOfFirst { it.id == id }; if (i >= 0) { l[i] = l[i].copy(pinned = !l[i].pinned); save(l) } }
}

data class Message(val id: String, val title: String, val body: String, val ts: Long, val read: Boolean, val kind: String = "系统")

object MessageRepo {
    private fun seed(): MutableList<Message> {
        val now = System.currentTimeMillis()
        val l = mutableListOf(
            Message(UUID.randomUUID().toString(), "欢迎使用豆包输入法（原生复刻）", "这是一款净室实现的开源复刻，非官方版本。你可以在设置中自定义键盘、语音与 AI 能力。", now - 3600_000, false, "系统"),
            Message(UUID.randomUUID().toString(), "新皮肤：晴空蓝已上线", "布局与显示中可切换浅色 / 深色 / 跟随系统，键盘外观会立即生效。", now - 86400_000, true, "活动"),
            Message(UUID.randomUUID().toString(), "隐私提醒", "AI 与语音只在你主动触发时使用网络。API Key 仅保存在本机，不会写入日志。", now - 172800_000, true, "安全")
        )
        save(l); return l
    }

    fun all(): MutableList<Message> {
        val arr = Prefs.getJsonArray(Prefs.K_MESSAGES)
        val out = mutableListOf<Message>()
        for (i in 0 until arr.length()) {
            val o = arr.optJSONObject(i) ?: continue
            out.add(Message(o.optString("id"), o.optString("title"), o.optString("body"), o.optLong("ts"), o.optBoolean("read"), o.optString("kind", "系统")))
        }
        if (out.isEmpty() && !Prefs.getBool("messages_seeded")) {
            val seeded = seed()
            Prefs.putBool("messages_seeded", true)
            return seeded
        }
        return out
    }

    fun save(list: List<Message>) {
        val arr = JSONArray()
        list.forEach { m ->
            arr.put(JSONObject().put("id", m.id).put("title", m.title).put("body", m.body).put("ts", m.ts).put("read", m.read).put("kind", m.kind))
        }
        Prefs.putJson(Prefs.K_MESSAGES, arr)
    }

    fun markRead(id: String) { val l = all(); val i = l.indexOfFirst { it.id == id }; if (i >= 0) { l[i] = l[i].copy(read = true); save(l) } }
    fun markAllRead() { save(all().map { it.copy(read = true) }) }
    fun delete(id: String) { val l = all(); l.removeAll { it.id == id }; save(l) }
    fun unreadCount(): Int = all().count { !it.read }
}

data class Feedback(val id: String, val type: String, val text: String, val contact: String, val ts: Long)

object FeedbackRepo {
    fun all(): MutableList<Feedback> {
        val arr = Prefs.getJsonArray(Prefs.K_FEEDBACK)
        val out = mutableListOf<Feedback>()
        for (i in 0 until arr.length()) {
            val o = arr.optJSONObject(i) ?: continue
            out.add(Feedback(o.optString("id"), o.optString("type"), o.optString("text"), o.optString("contact"), o.optLong("ts")))
        }
        return out
    }

    fun add(type: String, text: String, contact: String) {
        val arr = Prefs.getJsonArray(Prefs.K_FEEDBACK)
        arr.put(JSONObject().put("id", UUID.randomUUID().toString()).put("type", type).put("text", text).put("contact", contact).put("ts", System.currentTimeMillis()))
        Prefs.putJson(Prefs.K_FEEDBACK, arr)
    }

    fun delete(id: String) {
        val list = all().filter { it.id != id }
        val arr = JSONArray()
        list.forEach { f -> arr.put(JSONObject().put("id", f.id).put("type", f.type).put("text", f.text).put("contact", f.contact).put("ts", f.ts)) }
        Prefs.putJson(Prefs.K_FEEDBACK, arr)
    }
}

object DeviceRepo {
    data class Device(val name: String, val kind: String, val active: Boolean)
    fun devices(): MutableList<Device> {
        if (!Prefs.getBool("devices_seeded")) {
            Prefs.putBool("devices_seeded", true)
            return mutableListOf(Device("本机 · Android", "手机", true))
        }
        val arr = Prefs.getJsonArray(Prefs.K_SUPER_DEVICES)
        val out = mutableListOf<Device>()
        for (i in 0 until arr.length()) {
            val o = arr.optJSONObject(i) ?: continue
            out.add(Device(o.optString("name"), o.optString("kind"), o.optBoolean("active")))
        }
        if (out.isEmpty()) out.add(Device("本机 · Android", "手机", true))
        return out
    }

    fun save(list: List<Device>) {
        val arr = JSONArray()
        list.forEach { d -> arr.put(JSONObject().put("name", d.name).put("kind", d.kind).put("active", d.active)) }
        Prefs.putJson(Prefs.K_SUPER_DEVICES, arr)
    }

    fun addDevice(name: String, kind: String = "电脑") {
        val l = devices(); l.add(Device(name, kind, true)); save(l)
    }
}

object ToolbarRepo {
    val allIds = listOf("toolbox", "voice", "clipboard", "translate", "emoji", "phrase", "keyboard", "trad", "onehand", "handwrite", "undo", "ai")
    val default = allIds
    fun current(): MutableList<String> {
        val arr = Prefs.getJsonArray(Prefs.K_CUSTOM_TOOLBAR)
        val out = mutableListOf<String>()
        for (i in 0 until arr.length()) {
            val id = arr.optString(i)
            if (id in allIds && id !in out) out.add(id)
        }
        if (out.isEmpty()) out.addAll(default)
        return out
    }
    fun save(list: List<String>) {
        val arr = JSONArray(); list.filter { it in allIds }.distinct().forEach { arr.put(it) }
        Prefs.putJson(Prefs.K_CUSTOM_TOOLBAR, arr)
    }
    fun reset() { Prefs.putJson(Prefs.K_CUSTOM_TOOLBAR, JSONArray()) }
}
