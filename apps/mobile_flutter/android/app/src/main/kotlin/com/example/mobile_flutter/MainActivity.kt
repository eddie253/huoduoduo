package com.example.mobile_flutter

import android.accounts.AccountManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val GOOGLE_ACCOUNT_CHANNEL =
            "com.example.mobile_flutter/google_account"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            GOOGLE_ACCOUNT_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasGoogleAccount" -> {
                    result.success(hasGoogleAccount())
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun hasGoogleAccount(): Boolean? {
        return try {
            val accountManager = AccountManager.get(this)
            val googleAccounts = accountManager.getAccountsByType("com.google")
            googleAccounts.isNotEmpty()
        } catch (_: SecurityException) {
            null
        } catch (_: Throwable) {
            null
        }
    }
}
