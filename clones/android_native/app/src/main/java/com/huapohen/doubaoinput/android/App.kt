package com.huapohen.doubaoinput.android

import android.app.Application
import com.huapohen.doubaoinput.android.core.Prefs

class App : Application() {
    override fun onCreate() {
        super.onCreate()
        Prefs.init(this)
    }
}
