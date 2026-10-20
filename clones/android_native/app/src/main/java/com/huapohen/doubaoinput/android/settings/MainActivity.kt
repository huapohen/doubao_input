package com.huapohen.doubaoinput.android.settings

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.huapohen.doubaoinput.android.core.Prefs
import com.huapohen.doubaoinput.android.ime.DoubaoImeService

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        Prefs.init(this)
        setContent {
            com.huapohen.doubaoinput.android.settings.ui.DoubaoCloneApp(
                initialRoute = intent.getStringExtra(DoubaoImeService.EXTRA_ROUTE)
            )
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val route = intent.getStringExtra(DoubaoImeService.EXTRA_ROUTE)
        if (route != null) {
            // Compose app observes this value through the singleton navigation bus.
            com.huapohen.doubaoinput.android.settings.ui.NavBus.open(route)
        }
    }
}
