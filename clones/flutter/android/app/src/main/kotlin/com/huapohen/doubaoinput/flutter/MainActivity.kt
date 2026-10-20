package com.huapohen.doubaoinput.flutter

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import android.view.inputmethod.InputMethodManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.huapohen.doubaoinput.flutter/system"
    private val deepLinkName = "com.huapohen.doubaoinput.flutter/deeplink"
    private var deepLinkChannel: MethodChannel? = null
    private var pendingDeepLink: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        pendingDeepLink = intent?.dataString
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val url = intent.dataString ?: return
        pendingDeepLink = url
        deepLinkChannel?.invokeMethod("open", url)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        deepLinkChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, deepLinkName)
        deepLinkChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialUrl" -> {
                    result.success(pendingDeepLink)
                    pendingDeepLink = null
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "isImeEnabled" -> result.success(isImeEnabled())
                "openImeSettings" -> {
                    try {
                        startActivity(Intent(Settings.ACTION_INPUT_METHOD_SETTINGS))
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "showImePicker" -> {
                    try {
                        val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
                        imm.showInputMethodPicker()
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun isImeEnabled(): Boolean {
        return try {
            val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
            imm.enabledInputMethodList.any {
                it.packageName == packageName && it.serviceName == "$packageName.DoubaoImeService"
            }
        } catch (e: Exception) {
            false
        }
    }
}
