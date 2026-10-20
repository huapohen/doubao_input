package com.huapohen.doubaoinput.android.engine

import android.content.Context
import com.huapohen.doubaoinput.android.core.LexiconEntry
import org.json.JSONObject
import java.util.TreeMap
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Offline pinyin engine driven by assets/pinyin_dict.json (jieba + pypinyin, MIT).
 * Indexes full pinyin (flat), initials, and T9 digit strings. All queries are prefix based.
 */
object PinyinEngine {
    data class DictEntry(val w: String, val p: String, val f: Int)
    data class Candidate(
        val text: String,
        val pinyin: String,
        val freq: Int,
        val score: Double,
        val source: String = "dict",
        val learned: Boolean = false,
        val exact: Boolean = false
    )

    private val flatMap = TreeMap<String, MutableList<DictEntry>>()
    private val initialMap = TreeMap<String, MutableList<DictEntry>>()
    private val t9Map = TreeMap<String, MutableList<DictEntry>>()
    private val byFirstChar = HashMap<Char, MutableList<DictEntry>>()
    private val syllables = HashSet<String>()
    private val loaded = AtomicBoolean(false)
    private val latch = CountDownLatch(1)
    var entryCount: Int = 0
        private set
    var loadMillis: Long = 0
        private set

    @Volatile private var loading = false

    fun ensureLoaded(context: Context) {
        if (loaded.get()) return
        synchronized(this) {
            if (loading || loaded.get()) return
            loading = true
            val app = context.applicationContext
            Thread({
                val start = System.currentTimeMillis()
                try {
                    val text = app.assets.open("pinyin_dict.json").bufferedReader().use { it.readText() }
                    val arr = JSONObject(text).optJSONArray("entries")
                    if (arr != null) {
                        for (i in 0 until arr.length()) {
                            val o = arr.optJSONObject(i) ?: continue
                            val w = o.optString("w")
                            val p = o.optString("p")
                            val f = o.optInt("f", 1)
                            if (w.isBlank() || p.isBlank()) continue
                            val entry = DictEntry(w, p, f)
                            val flat = p.replace(" ", "").lowercase()
                            flatMap.getOrPut(flat) { mutableListOf() }.add(entry)
                            val ini = p.split(" ").mapNotNull { it.firstOrNull()?.toString() }.joinToString("").lowercase()
                            if (ini.isNotEmpty()) initialMap.getOrPut(ini) { mutableListOf() }.add(entry)
                            if (flat.length <= 30) t9Map.getOrPut(t9Digits(flat)) { mutableListOf() }.add(entry)
                            p.split(" ").forEach { s -> if (s.isNotBlank()) syllables.add(s.lowercase()) }
                            entryCount++
                        }
                    }
                    byFirstChar.clear()
                    flatMap.values.forEach { list ->
                        list.forEach { e ->
                            if (e.w.length in 2..4 && e.f > 3000) {
                                byFirstChar.getOrPut(e.w[0]) { mutableListOf() }.add(e)
                            }
                        }
                    }
                } catch (t: Throwable) {
                    // Leave engine empty; UI surfaces a clear "词库加载失败" state.
                } finally {
                    loadMillis = System.currentTimeMillis() - start
                    loaded.set(true)
                    loading = false
                    latch.countDown()
                }
            }, "pinyin-dict-loader").start()
        }
    }

    fun awaitLoaded(timeoutMs: Long = 1500): Boolean {
        if (loaded.get()) return true
        return try { latch.await(timeoutMs, TimeUnit.MILLISECONDS) } catch (t: InterruptedException) { false }
    }

    fun isReady(): Boolean = loaded.get()

    private fun t9Digits(s: String): String {
        val sb = StringBuilder(s.length)
        for (c in s) {
            when (c) {
                in "abc" -> sb.append('2'); in "def" -> sb.append('3'); in "ghi" -> sb.append('4')
                in "jkl" -> sb.append('5'); in "mno" -> sb.append('6'); in "pqrs" -> sb.append('7')
                in "tuv" -> sb.append('8'); in "wxyz" -> sb.append('9'); else -> {}
            }
        }
        return sb.toString()
    }

    /** Split a flat pinyin string into plausible syllables, greedy longest match. */
    fun splitSyllables(input: String): List<String> {
        val s = input.lowercase().replace("'", "")
        val out = ArrayList<String>()
        var i = 0
        while (i < s.length) {
            var matched: String? = null
            var len = minOf(6, s.length - i)
            while (len >= 1) {
                val cand = s.substring(i, i + len)
                if (syllables.contains(cand)) { matched = cand; break }
                len--
            }
            if (matched != null) {
                out.add(matched); i += matched.length
            } else {
                val end = minOf(i + 2, s.length)
                out.add(s.substring(i, end)); i = end
            }
        }
        return out
    }

    fun flatPinyin(input: String): String = input.lowercase().replace("'", "").replace(" ", "")

    fun isValidSyllable(s: String): Boolean = syllables.contains(s.lowercase())

    fun prettyPinyin(input: String): String {
        val parts = splitSyllables(input)
        return if (parts.size > 1 && parts.all { isValidSyllable(it) }) parts.joinToString("'") else input
    }

    /**
     * Main Chinese lookup. [rawInput] may be letters (26-key / shuangpin already converted)
     * or digits (T9).
     */
    fun candidates(
        rawInput: String,
        t9: Boolean = false,
        limit: Int = 60,
        fuzzyInitials: Set<String> = emptySet(),
        fuzzyFinals: Set<String> = emptySet(),
        fuzzySyllables: Set<String> = emptySet(),
        mru: Map<String, Long> = emptyMap(),
        lexicon: List<LexiconEntry> = emptyList(),
        blacklist: Set<String> = emptySet()
    ): List<Candidate> {
        if (!awaitLoaded()) return emptyList()
        val query = if (t9) rawInput.filter { it.isDigit() } else flatPinyin(rawInput)
        if (query.isEmpty()) return emptyList()
        val best = HashMap<String, Candidate>()
        val now = System.currentTimeMillis()
        val mruSorted = mru.entries.sortedByDescending { it.value }
        val mruRank = HashMap<String, Int>()
        mruSorted.take(400).forEachIndexed { idx, e -> mruRank[e.key] = idx }

        fun consider(text: String, pinyin: String, freq: Int, score: Double, source: String, exact: Boolean) {
            if (text.isBlank() || text in blacklist) return
            val learned = mruRank.containsKey(text)
            val learnBoost = if (learned) {
                val rank = mruRank[text] ?: 400
                val age = (now - (mru[text] ?: 0)) / 86_400_000.0
                val recency = (1.0 - rank / 400.0).coerceIn(0.0, 1.0)
                val freshness = (1.0 - age / 30.0).coerceIn(0.0, 1.0)
                60_000.0 + 120_000.0 * (0.5 * recency + 0.5 * freshness)
            } else 0.0
            val finalScore = score + learnBoost
            val prev = best[text]
            if (prev == null || finalScore > prev.score) {
                best[text] = Candidate(text, pinyin, freq, finalScore, source, learned, exact)
            }
        }

        val queries = ArrayList<String>()
        queries.add(query)
        if (!t9) fuzzyInitials.forEach { pair ->
            val parts = pair.split("/")
            if (parts.size == 2) {
                if (query.startsWith(parts[0])) queries.add(parts[1] + query.substring(parts[0].length))
                if (query.startsWith(parts[1])) queries.add(parts[0] + query.substring(parts[1].length))
                if (query.contains(parts[0])) queries.add(query.replace(parts[0], parts[1]))
                if (query.contains(parts[1])) queries.add(query.replace(parts[1], parts[0]))
            }
        }
        if (!t9) fuzzyFinals.forEach { pair ->
            val parts = pair.split("/")
            if (parts.size == 2) {
                if (query.endsWith(parts[0])) queries.add(query.dropLast(parts[0].length) + parts[1])
                if (query.endsWith(parts[1])) queries.add(query.dropLast(parts[1].length) + parts[0])
            }
        }
        if (!t9) fuzzySyllables.forEach { pair ->
            val parts = pair.split("/")
            if (parts.size == 2) {
                if (query.contains(parts[0])) queries.add(query.replace(parts[0], parts[1]))
                if (query.contains(parts[1])) queries.add(query.replace(parts[1], parts[0]))
            }
        }
        val distinctQueries = queries.distinct().take(20)

        distinctQueries.forEachIndexed { qIndex, q ->
            val variantWeight = if (qIndex == 0) 1.0 else 0.72
            val exactKey = q
            if (t9) {
                scanPrefix(t9Map, q) { entry, key, exact ->
                    val extra = (key.length - q.length)
                    val score = entry.f * (if (exact) 2.2 else 1.0) / (1.0 + extra * 0.22) * variantWeight
                    consider(entry.w, entry.p, entry.f, score, "dict", exact)
                }
            } else {
                scanPrefix(flatMap, q) { entry, key, exact ->
                    val extra = (key.length - q.length)
                    val lenPenalty = 1.0 + extra * 0.16
                    val exactBonus = if (exact) 2.0 else 1.0
                    val lengthBias = when (entry.w.length) {
                        1 -> if (q.length <= 2) 1.25 else 0.85
                        2 -> 1.12
                        in 3..4 -> 1.04
                        else -> 0.94
                    }
                    val score = entry.f * exactBonus * lengthBias / lenPenalty * variantWeight
                    consider(entry.w, entry.p, entry.f, score, "dict", exact)
                }
                // Initials / 简拼 matches (nh -> 你好)
                scanPrefix(initialMap, q) { entry, key, exact ->
                    if (entry.w.length >= 2) {
                        val score = entry.f * (if (exact) 0.95 else 0.55) * variantWeight
                        consider(entry.w, entry.p, entry.f, score, "initials", exact)
                    }
                }
            }
        }

        // Personal lexicon has priority over the general dictionary.
        lexicon.forEach { e ->
            if (e.word.isBlank()) return@forEach
            val p = flatPinyin(e.pinyin)
            val isMatch = when {
                p.isNotEmpty() -> p.startsWith(query) || (p.length > 1 && p.take(1) == query) ||
                    initialsOfPinyin(e.pinyin).startsWith(query) || e.word.startsWith(rawInput)
                else -> false
            }
            if (isMatch) consider(e.word, e.pinyin, 1_000_000, 1_000_000.0, "lexicon", p == query)
        }

        // Exact single-character fallback: allow 简拼 first letters and make results non-empty.
        if (best.isEmpty() && !t9 && query.length <= 6) {
            val firstSyl = splitSyllables(query).firstOrNull() ?: query
            if (firstSyl != query) {
                scanPrefix(flatMap, firstSyl) { entry, key, _ ->
                    if (entry.w.length == 1) consider(entry.w, entry.p, entry.f, entry.f * 0.8, "dict", false)
                }
            }
        }

        return best.values.sortedWith(
            compareByDescending<Candidate> { it.score }.thenByDescending { it.freq }
                .thenBy { it.text.length }
        ).take(limit)
    }

    private fun initialsOfPinyin(p: String): String =
        p.trim().split(" ").mapNotNull { it.firstOrNull()?.toString() }.joinToString("")

    private inline fun scanPrefix(
        map: TreeMap<String, MutableList<DictEntry>>,
        prefix: String,
        consume: (DictEntry, String, Boolean) -> Unit
    ) {
        if (prefix.isEmpty()) return
        val sub = try { map.subMap(prefix, true, prefix + '\uffff', false) } catch (t: Throwable) { return }
        var scanned = 0
        var entries = 0
        for ((key, list) in sub) {
            val exact = key == prefix
            for (e in list) {
                consume(e, key, exact)
                entries++
                if (entries > 3500) return
            }
            scanned++
            if (scanned > 2500) return
        }
    }

    /** Data-driven association: high-frequency words beginning with the last committed char. */
    fun associations(lastWord: String, limit: Int = 6): List<String> {
        if (!loaded.get() || lastWord.isBlank()) return emptyList()
        val ch = lastWord.last()
        val list = byFirstChar[ch] ?: return emptyList()
        val out = ArrayList<String>()
        for (e in list.sortedByDescending { it.f }) {
            if (e.w == lastWord) continue
            if (e.w.startsWith(lastWord) && lastWord.length > 1) continue
            if (out.contains(e.w)) continue
            out.add(e.w)
            if (out.size >= limit) break
        }
        return out
    }

    fun frequentWords(prefix: String, limit: Int = 8): List<String> {
        if (!loaded.get()) return emptyList()
        val out = ArrayList<String>()
        val sub = try { flatMap.subMap(prefix, true, prefix + '\uffff', false) } catch (t: Throwable) { return emptyList() }
        sub.values.asSequence().flatten().filter { it.w.length >= 2 }.sortedByDescending { it.f }.take(limit).forEach { out.add(it.w) }
        return out
    }

    fun hasPinyin(pinyinFlat: String): Boolean = flatMap.containsKey(pinyinFlat)

    fun findPinyinForWord(word: String): String {
        if (!loaded.get()) return ""
        val sub = flatMap.entries.firstOrNull { (_, list) -> list.any { it.w == word } } ?: return ""
        return sub.value.firstOrNull { it.w == word }?.p ?: ""
    }

    // ---- Double pinyin (小鹤 / 自然码) ----
    private val xiaoheFinals = mapOf(
        "iu" to "q", "ei" to "w", "e" to "e", "er" to "r", "uan" to "r", "ue" to "t", "un" to "y",
        "u" to "u", "sh" to "u", "i" to "i", "ch" to "i", "o" to "o", "uo" to "o", "ie" to "p",
        "a" to "a", "iong" to "s", "ong" to "s", "ai" to "d", "en" to "f", "eng" to "g", "ang" to "h",
        "an" to "j", "ing" to "k", "uai" to "k", "iang" to "l", "uang" to "l", "ou" to "z",
        "ia" to "x", "ua" to "x", "ao" to "c", "ve" to "v", "in" to "b", "iao" to "n", "ian" to "m"
    )
    private val ziranFinals = mapOf(
        "iu" to "q", "ei" to "z", "e" to "e", "er" to "r", "uan" to "r", "ue" to "t", "un" to "p",
        "u" to "u", "sh" to "u", "i" to "i", "ch" to "i", "o" to "o", "uo" to "o", "ie" to "x",
        "a" to "a", "iong" to "s", "ong" to "s", "ai" to "l", "en" to "f", "eng" to "g", "ang" to "h",
        "an" to "j", "ing" to "y", "uai" to "y", "iang" to "d", "uang" to "d", "ou" to "b",
        "ia" to "w", "ua" to "w", "ao" to "k", "ve" to "t", "in" to "n", "iao" to "c", "ian" to "m"
    )
    private val initialLetters = listOf("zh", "ch", "sh", "b", "p", "m", "f", "d", "t", "n", "l", "g", "k", "h", "j", "q", "x", "r", "z", "c", "s", "y", "w")

    fun shuangpinToPinyin(code: String, scheme: String): String {
        val finals = if (scheme == "ziran") ziranFinals else xiaoheFinals
        val finalByCode = HashMap<String, String>()
        finals.forEach { (fin, c) -> if (fin != "sh" && fin != "ch") finalByCode.putIfAbsent(c, fin) }
        val out = ArrayList<String>()
        var i = 0
        val s = code.lowercase()
        while (i < s.length) {
            // initial
            val init = initialLetters.firstOrNull { s.startsWith(it, i) }
            if (init != null) {
                if (i + init.length >= s.length) { out.add(init); i += init.length; continue }
                val finalCode = s[i + init.length].toString()
                val fin = finalByCode[finalCode]
                if (fin != null) {
                    out.add(init + fin); i += init.length + 1
                } else {
                    out.add(init); i += init.length
                }
            } else {
                val one = s[i].toString()
                val fin = finalByCode[one]
                if (fin != null && i + 1 < s.length) { out.add(fin); i += 1 }
                else if (fin != null) { out.add(fin); i += 1 }
                else { out.add(one); i += 1 }
            }
        }
        return out.joinToString(" ")
    }

    val englishWords = listOf(
        "the","be","to","of","and","a","in","that","have","I","it","for","not","on","with","he","as","you","do","at",
        "this","but","his","by","from","they","we","say","her","she","or","an","will","my","one","all","would","there",
        "their","what","so","up","out","if","about","who","get","which","go","me","when","make","can","like","time",
        "no","just","him","know","take","people","into","year","your","good","some","could","them","see","other","than",
        "then","now","look","only","come","its","over","think","also","back","after","use","two","how","our","work",
        "first","well","way","even","new","want","because","any","these","give","day","most","us","hello","thanks",
        "thank","please","sorry","yes","okay","great","love","happy","morning","night","today","tomorrow","message",
        "call","home","work","team","meeting","project","email","phone","password","search","send","input","keyboard",
        "chinese","english","android","app","download","update","settings","privacy","clipboard","translate","voice",
        "writing","friend","family","dinner","lunch","coffee","weekend","travel","photo","music","video","tomorrow",
        "morning","evening","question","answer","problem","solution","welcome","congratulations","birthday","holiday",
        "restaurant","address","number","name","city","country","school","company","office","computer","internet"
    ).distinct()

    fun englishSuggestions(prefix: String, mru: Map<String, Long>, limit: Int = 8): List<String> {
        val p = prefix.lowercase()
        if (p.isEmpty()) return emptyList()
        val out = LinkedHashSet<String>()
        mru.keys.filter { it.length > 1 && it.all { c -> c.isLetter() } && it.lowercase().startsWith(p) }
            .sortedByDescending { mru[it] }.take(3).forEach { out.add(it) }
        englishWords.asSequence().filter { it.startsWith(p) }
            .sortedBy { it.length }.take(limit).forEach { out.add(it) }
        return out.take(limit).toList()
    }
}
