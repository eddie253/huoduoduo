package com.example.mobile_flutter

import android.accounts.AccountManager
import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.content.pm.PackageManager
import android.telephony.TelephonyManager
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val GOOGLE_ACCOUNT_CHANNEL =
            "com.example.mobile_flutter/google_account"
        private const val NETWORK_SIGNAL_CHANNEL =
            "com.example.mobile_flutter/network_signal"
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

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NETWORK_SIGNAL_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getMobileNetworkGeneration" -> {
                    result.success(getMobileNetworkGeneration())
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun hasGoogleAccount(): Boolean? {
        return try {
            val hasGetAccountsPermission =
                ContextCompat.checkSelfPermission(
                    this,
                    android.Manifest.permission.GET_ACCOUNTS,
                ) == PackageManager.PERMISSION_GRANTED
            if (!hasGetAccountsPermission) {
                // Android account visibility rules vary by OS/version/permission.
                // If permission is unavailable, treat this as unknown instead of missing.
                return null
            }
            val accountManager = AccountManager.get(this)
            val googleAccounts = accountManager.getAccountsByType("com.google")
            googleAccounts.isNotEmpty()
        } catch (_: SecurityException) {
            null
        } catch (_: Throwable) {
            null
        }
    }

    private fun getMobileNetworkGeneration(): String {
        return try {
            val connectivityManager =
                getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            val activeNetwork = connectivityManager.activeNetwork ?: return "none"
            val capabilities =
                connectivityManager.getNetworkCapabilities(activeNetwork) ?: return "unknown"
            if (!capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR)) {
                return "unknown"
            }

            val telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
            when (telephonyManager.dataNetworkType) {
                TelephonyManager.NETWORK_TYPE_GPRS,
                TelephonyManager.NETWORK_TYPE_EDGE,
                TelephonyManager.NETWORK_TYPE_CDMA,
                TelephonyManager.NETWORK_TYPE_1xRTT,
                TelephonyManager.NETWORK_TYPE_IDEN,
                TelephonyManager.NETWORK_TYPE_GSM,
                    -> "2g"

                TelephonyManager.NETWORK_TYPE_UMTS,
                TelephonyManager.NETWORK_TYPE_EVDO_0,
                TelephonyManager.NETWORK_TYPE_EVDO_A,
                TelephonyManager.NETWORK_TYPE_HSDPA,
                TelephonyManager.NETWORK_TYPE_HSUPA,
                TelephonyManager.NETWORK_TYPE_HSPA,
                TelephonyManager.NETWORK_TYPE_EVDO_B,
                TelephonyManager.NETWORK_TYPE_EHRPD,
                TelephonyManager.NETWORK_TYPE_HSPAP,
                TelephonyManager.NETWORK_TYPE_TD_SCDMA,
                    -> "3g"

                TelephonyManager.NETWORK_TYPE_LTE,
                TelephonyManager.NETWORK_TYPE_IWLAN,
                    -> "4g"

                TelephonyManager.NETWORK_TYPE_NR -> "5g"
                else -> "unknown"
            }
        } catch (_: SecurityException) {
            "unknown"
        } catch (_: Throwable) {
            "unknown"
        }
    }
}
