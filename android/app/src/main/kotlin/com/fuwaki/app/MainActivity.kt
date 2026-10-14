package com.fuwaki.app

import android.os.Handler
import android.os.Looper
import com.amap.api.location.AMapLocation
import com.amap.api.location.AMapLocationClient
import com.amap.api.location.AMapLocationClientOption
import com.amap.api.location.AMapLocationListener
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.fuwaki.app/location"
    private var sdkReady = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.platformViewsController.registry.registerViewFactory(
            "com.fuwaki.app/amap", NativeAmapFactory(this, flutterEngine.dartExecutor.binaryMessenger)
        )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setApiKey" -> {
                        val key = call.argument<String>("key") ?: ""
                        AMapLocationClient.setApiKey(key)
                        AMapLocationClient.updatePrivacyShow(this@MainActivity, true, true)
                        AMapLocationClient.updatePrivacyAgree(this@MainActivity, true)
                        sdkReady = true
                        result.success(true)
                    }
                    "getLocation" -> {
                        if (!sdkReady) {
                            // Preserve SDK positioning independently of map rendering.
                            // Do not overwrite a manifest/cached SDK key with an empty value.
                            AMapLocationClient.updatePrivacyShow(this@MainActivity, true, true)
                            AMapLocationClient.updatePrivacyAgree(this@MainActivity, true)
                            sdkReady = true
                        }
                        getLocation(result)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun getLocation(result: MethodChannel.Result) {
        val client = AMapLocationClient(this)
        val option = AMapLocationClientOption().apply {
            isOnceLocation = true
            isNeedAddress = true
            httpTimeOut = 15000
        }
        client.setLocationOption(option)

        var hasResult = false

        client.setLocationListener(object : AMapLocationListener {
            override fun onLocationChanged(location: AMapLocation?) {
                if (hasResult) return
                hasResult = true

                if (location == null || location.errorCode != 0) {
                    val err = mapOf(
                        "errorCode" to (location?.errorCode ?: -1),
                        "errorInfo" to (location?.errorInfo ?: "定位失败")
                    )
                    Handler(Looper.getMainLooper()).post {
                        result.success(err)
                        client.onDestroy()
                    }
                    return
                }

                val loc = mapOf(
                    "city" to (location.city ?: ""),
                    "province" to (location.province ?: ""),
                    "district" to (location.district ?: ""),
                    "address" to (location.address ?: ""),
                    "latitude" to location.latitude,
                    "longitude" to location.longitude,
                )
                Handler(Looper.getMainLooper()).post {
                    result.success(loc)
                    client.onDestroy()
                }
            }
        })

        client.startLocation()
    }
}
