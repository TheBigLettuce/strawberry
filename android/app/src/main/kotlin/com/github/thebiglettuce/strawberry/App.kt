package com.github.thebiglettuce.strawberry

import android.app.Application
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.os.StrictMode

class App : Application() {
    override fun onCreate() {
        super.onCreate()
        val appFlags = applicationInfo.flags
        if ((appFlags and ApplicationInfo.FLAG_DEBUGGABLE) != 0) {
            StrictMode.setThreadPolicy(
                StrictMode.ThreadPolicy.Builder().detectAll().build()
            )
            StrictMode.setVmPolicy(
                StrictMode.VmPolicy.Builder().detectAll().build()
            )
        }
    }
}

class LocaleBroadcastReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_LOCALE_CHANGED) {
//            createNotifChannels(context)
        }
    }
}