package com.huapohen.doubaoinput.android.core

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import androidx.compose.runtime.mutableIntStateOf
import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID

/**
 * Single source of truth for all persisted settings, shared by the settings app and the IME
 * (both run in the same process). Mirrors the key names from CLONE_SPEC section 7.
 */
object Prefs {
    const val K_ONBOARDING_DONE = "onboarding_done"
    const val K_PRIVACY_DONE = "privacy_done"
    const val K_PRIVACY_MODE = "privacy_mode"
    const val K_KEYBOARD_TYPE = "keyboard_type"
    const val K_KEYBOARD_TYPE_CHOSEN = "keyboard_type_chosen"
    const val K_THEME_MODE = "theme_mode"
    const val K_INPUT_MODE = "input_mode"
    const val K_FUZZY_ENABLED = "fuzzy_enabled"
    const val K_FUZZY_INITIALS = "fuzzy_initials"
    const val K_FUZZY_FINALS = "fuzzy_finals"
    const val K_FUZZY_SYLLABLES = "fuzzy_syllables"
    const val K_ASSOCIATION = "association_enabled"
    const val K_PRED_EMOJI = "prediction_emoji"
    const val K_PRED_IMAGE = "prediction_image"
    const val K_PRED_KAOMOJI = "prediction_kaomoji"
    const val K_KEY_SOUND = "key_sound"
    const val K_KEY_SOUND_VOLUME = "key_sound_volume"
    const val K_KEY_VIBRATE = "key_vibrate"
    const val K_KEY_VIBRATE_LEVEL = "key_vibrate_level"
    const val K_KEY_BUBBLE = "key_bubble"
    const val K_KEY_RESPONSE = "key_response"
    const val K_QUICK_SPACE = "quick_space"
    const val K_QUICK_CAPITALIZE = "quick_capitalize"
    const val K_QUICK_DOUBLE_SPACE = "quick_double_space_period"
    const val K_CLIPBOARD_CANDIDATE = "clipboard_candidate"
    const val K_CLIPBOARD_HISTORY = "clipboard_history"
    const val K_VOICE_SMART_ORGANIZE = "voice_smart_organize"
    const val K_VOICE_PUNCTUATION = "voice_punctuation"
    const val K_VOICE_FILLER = "voice_filler"
    const val K_VOICE_OFFLINE = "voice_offline"
    const val K_VOICE_OFFLINE_PROGRESS = "voice_offline_progress"
    const val K_VOICE_KEY = "voice_key"
    const val K_VOICE_WIFI = "voice_wifi_cellular"
    const val K_VOICE_HEADSET = "voice_headset"
    const val K_VOICE_SEGMENT = "voice_segment"
    const val K_VOICE_ACTION_ENABLED = "voice_action_enabled"
    const val K_VOICE_ACTIONS = "voice_actions"
    const val K_CANDIDATE_FONT_SIZE = "candidate_font_size"
    const val K_PINYIN_LOCATION = "pinyin_location"
    const val K_DIGIT_MERGED = "digit_symbol_merged"
    const val K_COMMA_PERIOD = "comma_period_separate"
    const val K_ZH_EN_POSITION = "zh_en_position"
    const val K_SLIDE_SYMBOLS = "slide_symbols"
    const val K_SIDEBAR_SYMBOLS = "sidebar_symbols"
    const val K_ENTER_SEND = "enter_send"
    const val K_TRAD_OUTPUT = "trad_output"
    const val K_ONE_HAND = "one_hand"
    const val K_FLOATING = "floating"
    const val K_KEYBOARD_HEIGHT = "keyboard_height"
    const val K_KEYBOARD_BOTTOM_GAP = "keyboard_bottom_gap"
    const val K_CUSTOM_TOOLBAR = "custom_toolbar"
    const val K_COMMON_PHRASES = "common_phrases"
    const val K_PERSONAL_LEXICON = "personal_lexicon"
    const val K_CLIPBOARD_ITEMS = "clipboard_items"
    const val K_MRU = "mru"
    const val K_BLACKLIST = "blacklist"
    const val K_AI_BASE_URL = "ai_base_url"
    const val K_AI_MODEL = "ai_model"
    const val K_AI_KEY = "ai_key"
    const val K_ACCOUNT_LOGGED_IN = "account_logged_in"
    const val K_ACCOUNT_NAME = "account_name"
    const val K_ACCOUNT_ID = "account_id"
    const val K_SYNC_SETTINGS = "sync_settings"
    const val K_SYNC_LEXICON = "sync_lexicon"
    const val K_SYNC_PHRASES = "sync_phrases"
    const val K_SUPER_TRANSFER = "super_transfer"
    const val K_SUPER_DEVICES = "super_devices"
    const val K_SMART_CLOUD_INPUT = "smart_cloud_input"
    const val K_SMART_CLOUD_LEXICON = "smart_cloud_lexicon"
    const val K_EXPERIENCE_PLAN = "experience_plan"
    const val K_AUX_INPUT = "aux_input"
    const val K_VERIFY_FILL = "verify_fill"
    const val K_CONTACTS_IMPORT = "contacts_import"
    const val K_MISTOUCH = "mistouch_prevention"
    const val K_DOUBLE_PINYIN = "double_pinyin_scheme"
    const val K_WUBI_HINT = "wubi_hint"
    const val K_WUBI_MIX = "wubi_mix"
    const val K_WUBI_UNIQUE = "wubi_unique"
    const val K_WUBI_FIFTH = "wubi_fifth"
    const val K_DID = "did"
    const val K_FEEDBACK = "feedback_items"
    const val K_MESSAGES = "messages"
    const val K_MESSAGES_READ = "messages_read"
    const val K_BANNER_INDEX = "banner_index"
    const val K_LAST_TAB = "last_tab"
    const val K_AI_SERVICE_ENABLED = "ai_service_enabled"
    const val K_THEME_ACCENT = "theme_accent"
    const val K_KEYBOARD_TYPE_PREVIEW_SEEN = "keyboard_preview_seen"

    lateinit var sp: SharedPreferences
        private set
    private var secure: SharedPreferences? = null
    private val _revision = mutableIntStateOf(0)
    val revision: Int get() = _revision.intValue

    fun init(ctx: Context) {
        if (::sp.isInitialized) return
        sp = ctx.applicationContext.getSharedPreferences("doubao_clone", Context.MODE_PRIVATE)
        secure = try {
            val mk = MasterKey.Builder(ctx.applicationContext)
                .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
                .build()
            EncryptedSharedPreferences.create(
                ctx.applicationContext,
                "doubao_secure",
                mk,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
            )
        } catch (t: Throwable) {
            null
        }
        if (!sp.contains(K_DID)) {
            sp.edit().putString(K_DID, UUID.randomUUID().toString()).apply()
        }
    }

    fun bump() { _revision.intValue = _revision.intValue + 1 }

    fun getString(key: String, def: String = ""): String = sp.getString(key, def) ?: def
    fun getBool(key: String, def: Boolean = false): Boolean = sp.getBoolean(key, def)
    fun getInt(key: String, def: Int = 0): Int = sp.getInt(key, def)
    fun getLong(key: String, def: Long = 0L): Long = sp.getLong(key, def)
    fun getStringSet(key: String, def: Set<String> = emptySet()): Set<String> =
        sp.getStringSet(key, def)?.toSet() ?: def

    fun putString(key: String, value: String) { sp.edit().putString(key, value).apply(); bump() }
    fun putBool(key: String, value: Boolean) { sp.edit().putBoolean(key, value).apply(); bump() }
    fun putInt(key: String, value: Int) { sp.edit().putInt(key, value).apply(); bump() }
    fun putLong(key: String, value: Long) { sp.edit().putLong(key, value).apply(); bump() }
    fun putStringSet(key: String, value: Set<String>) { sp.edit().putStringSet(key, value).apply(); bump() }

    // ---- shortcuts / defaults ----
    val onboardingDone get() = getBool(K_ONBOARDING_DONE)
    val privacyDone get() = getBool(K_PRIVACY_DONE)
    val smartMode get() = getString(K_PRIVACY_MODE, "smart") == "smart"
    val keyboardType get() = getString(K_KEYBOARD_TYPE, "pinyin26")
    val themeMode get() = getString(K_THEME_MODE, "system")
    val inputMode get() = getString(K_INPUT_MODE, "zh")
    val fuzzyEnabled get() = getBool(K_FUZZY_ENABLED)
    val associationEnabled get() = getBool(K_ASSOCIATION, true)
    val keySound get() = getBool(K_KEY_SOUND, true)
    val keyVibrate get() = getBool(K_KEY_VIBRATE, true)
    val keyBubble get() = getBool(K_KEY_BUBBLE, true)
    val clipboardCandidate get() = getBool(K_CLIPBOARD_CANDIDATE, true)
    val clipboardHistory get() = getBool(K_CLIPBOARD_HISTORY, true)
    val candidateFontSize get() = getInt(K_CANDIDATE_FONT_SIZE, 20)
    val keyboardHeight get() = getInt(K_KEYBOARD_HEIGHT, 0)
    val keyboardBottomGap get() = getInt(K_KEYBOARD_BOTTOM_GAP, 0)
    val oneHand get() = getString(K_ONE_HAND, "off")
    val floating get() = getBool(K_FLOATING)
    val enterSend get() = getBool(K_ENTER_SEND)
    val aiBaseUrl get() = getString(K_AI_BASE_URL, "https://api.deepseek.com")
    val aiModel get() = getString(K_AI_MODEL, "deepseek-chat")
    val aiEnabled get() = getBool(K_AI_SERVICE_ENABLED, true)
    val did get() = getString(K_DID)
    val accountLoggedIn get() = getBool(K_ACCOUNT_LOGGED_IN)
    val accountName get() = getString(K_ACCOUNT_NAME, "豆包用户")

    fun aiKey(): String {
        val fromSecure = try { secure?.getString(K_AI_KEY, "") } catch (t: Throwable) { "" }
        val fromPlain = if (!fromSecure.isNullOrBlank()) "" else getString(K_AI_KEY, "")
        val value = when {
            !fromSecure.isNullOrBlank() -> fromSecure
            !fromPlain.isNullOrBlank() -> fromPlain
            else -> ""
        }
        return value.trim()
    }

    fun hasAiKey(): Boolean = aiKey().isNotBlank()

    fun setAiKey(value: String) {
        val trimmed = value.trim()
        val savedSecurely = try {
            secure?.edit()?.putString(K_AI_KEY, trimmed)?.commit() ?: false
        } catch (t: Throwable) { false }
        if (!savedSecurely) {
            sp.edit().putString(K_AI_KEY, trimmed).apply()
        } else {
            sp.edit().remove(K_AI_KEY).apply()
        }
        bump()
    }

    fun secureStorageActive(): Boolean = secure != null

    fun aiKeyInSecureStorage(): Boolean = try {
        secure?.getString(K_AI_KEY, "")?.isNotBlank() == true
    } catch (t: Throwable) { false }


    fun sidebarSymbols(): List<String> {
        val arr = getJsonArray(K_SIDEBAR_SYMBOLS)
        val out = mutableListOf<String>()
        for (i in 0 until arr.length()) {
            val v = arr.optString(i)
            if (v.isNotBlank() && v !in out) out.add(v)
        }
        if (out.isEmpty()) out.addAll(listOf("，", "。", "？", "！"))
        return out.take(6)
    }

    fun setSidebarSymbols(list: List<String>) {
        val arr = JSONArray()
        list.filter { it.isNotBlank() }.distinct().take(6).forEach { arr.put(it) }
        putJson(K_SIDEBAR_SYMBOLS, arr)
    }

    // ---- JSON helpers ----
    fun getJsonArray(key: String): JSONArray = try {
        JSONArray(getString(key, "[]"))
    } catch (t: Throwable) { JSONArray() }

    fun getJsonObject(key: String): JSONObject = try {
        JSONObject(getString(key, "{}"))
    } catch (t: Throwable) { JSONObject() }

    fun putJson(key: String, arr: JSONArray) = putString(key, arr.toString())
    fun putJson(key: String, obj: JSONObject) = putString(key, obj.toString())

    // ---- MRU learning ----
    fun mru(): MutableMap<String, Long> {
        val obj = getJsonObject(K_MRU)
        val out = LinkedHashMap<String, Long>()
        obj.keys().forEach { k -> out[k] = obj.optLong(k, 0L) }
        return out
    }

    fun learnWord(word: String) {
        if (word.isBlank() || word.length > 30) return
        val obj = getJsonObject(K_MRU)
        obj.put(word, System.currentTimeMillis())
        if (obj.length() > 600) {
            val sorted = obj.keys().asSequence().sortedBy { obj.optLong(it) }
            sorted.take(obj.length() - 500).forEach { obj.remove(it) }
        }
        sp.edit().putString(K_MRU, obj.toString()).apply()
    }

    fun blacklist(): MutableSet<String> {
        val arr = getJsonArray(K_BLACKLIST)
        val out = LinkedHashSet<String>()
        for (i in 0 until arr.length()) out.add(arr.optString(i))
        return out
    }

    fun blacklistAdd(word: String) {
        val set = blacklist(); set.add(word)
        val arr = JSONArray(); set.forEach { arr.put(it) }
        sp.edit().putString(K_BLACKLIST, arr.toString()).apply(); bump()
    }

    fun blacklistRemove(word: String) {
        val set = blacklist(); set.remove(word)
        val arr = JSONArray(); set.forEach { arr.put(it) }
        sp.edit().putString(K_BLACKLIST, arr.toString()).apply(); bump()
    }
}
