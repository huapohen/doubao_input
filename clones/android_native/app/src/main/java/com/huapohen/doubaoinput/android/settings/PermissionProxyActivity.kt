package com.huapohen.doubaoinput.android.settings

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.huapohen.doubaoinput.android.ime.DoubaoImeService

/** Invisible helper that requests RECORD_AUDIO on behalf of the IME, then reports back to it. */
class PermissionProxyActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.setBackgroundDrawableResource(android.R.color.transparent)
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED) {
            notify(true)
            return
        }
        ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.RECORD_AUDIO), 42)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 42) {
            notify(grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED)
        }
    }

    private fun notify(granted: Boolean) {
        val action = if (granted) DoubaoImeService.ACTION_MIC_GRANTED else DoubaoImeService.ACTION_MIC_DENIED
        try {
            startService(Intent(this, DoubaoImeService::class.java).setAction(action))
        } catch (t: Throwable) { }
        finish()
        overridePendingTransition(0, 0)
    }
}
