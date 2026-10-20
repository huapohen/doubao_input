package com.huapohen.doubaoinput.flutter

import android.content.Context
import org.json.JSONObject
import java.util.concurrent.Executors

/**
 * Small native pinyin index used by the system IME service. It shares the same
 * clean-room dictionary as the Flutter app (assets/pinyin_dict.json) but keeps
 * its own compact in-memory index so the IME does not need a Flutter engine.
 */
class PinyinImeEngine {
    data class Entry(val word: String, val flat: String, val initials: String, val freq: Long)

    @Volatile
    var loaded = false
        private set
    var loadMillis = 0L
        private set

    private var entries: List<Entry> = emptyList()
    private val executor = Executors.newSingleThreadExecutor()
    private val recent = ArrayList<String>()

    fun load(context: Context) {
        val sw = System.currentTimeMillis()
        try {
            val text = context.assets.open("pinyin_dict.json").bufferedReader().use { it.readText() }
            val root = JSONObject(text)
            val arr = root.getJSONArray("entries")
            val list = ArrayList<Entry>(arr.length())
            for (i in 0 until arr.length()) {
                val o = arr.getJSONObject(i)
                val word = o.optString("w")
                val p = o.optString("p").lowercase()
                if (word.isEmpty() || p.isEmpty()) continue
                val flat = p.replace(" ", "")
                val initials = p.split(" ").filter { it.isNotEmpty() }
                    .map { it[0] }.joinToString("")
                list.add(Entry(word, flat, initials, o.optLong("f", 0)))
            }
            entries = list
            loaded = true
        } catch (e: Exception) {
            loaded = false
        }
        loadMillis = System.currentTimeMillis() - sw
    }

    fun loadAsync(context: Context) {
        executor.execute { load(context) }
    }

    fun query(q: String, limit: Int = 24): List<Entry> {
        if (!loaded || q.isEmpty()) return emptyList()
        val query = q.replace("'", "").lowercase()
        val out = ArrayList<Entry>(128)
        for (e in entries) {
            if (e.flat.startsWith(query) || e.initials == query) {
                out.add(e)
            }
        }
        val rec = recent.withIndex().associate { it.value to it.index }
        out.sortWith(compareByDescending<Entry> {
            val mru = rec[it.word]?.let { idx -> 1.0 + 3.0 / (1 + idx) } ?: 1.0
            val exact = if (it.flat == query) 2.6 else 1.0
            it.freq * exact * mru * (1.0 + (it.word.length - 1) * 0.06)
        }.thenByDescending { it.freq })
        return if (out.size > limit) ArrayList(out.subList(0, limit)) else out
    }

    fun learn(word: String) {
        if (word.isEmpty()) return
        recent.remove(word)
        recent.add(0, word)
        if (recent.size > 100) recent.removeAt(recent.size - 1)
    }

    fun shutdown() {
        executor.shutdownNow()
    }
}
