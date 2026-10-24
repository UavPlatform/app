package com.fuwaki.app

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.os.Handler
import android.os.Looper
import com.amap.api.location.AMapLocation
import com.amap.api.location.AMapLocationClient
import com.amap.api.location.AMapLocationClientOption
import io.flutter.plugin.common.MethodChannel

/** Explicit foreground opt-in, one fresh GCJ02 fix; independent of legacy city/map positioning. */
class DispatchLocationRequest(private val activity: Activity) {
    companion object { const val PERMISSION_REQUEST = 31042 }
    private val handler = Handler(Looper.getMainLooper())
    private var pending: MethodChannel.Result? = null
    private var client: AMapLocationClient? = null
    private val timeout = Runnable { finish(null, "LOCATION_TIMEOUT") }

    fun request(result: MethodChannel.Result) {
        if (pending != null) { result.error("LOCATION_BUSY", "定位正在进行", null); return }
        pending = result
        handler.postDelayed(timeout, 25000)
        if (!hasPermission()) {
            activity.requestPermissions(arrayOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION), PERMISSION_REQUEST)
        } else start()
    }
    fun permissionResult() {
        if (pending == null) return
        if (hasPermission()) start() else finish(null, "LOCATION_PERMISSION_DENIED")
    }
    private fun hasPermission() = activity.checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED ||
        activity.checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED

    private fun start() {
        try {
            val locator = AMapLocationClient(activity)
            client = locator
            locator.setLocationOption(AMapLocationClientOption().apply {
                isOnceLocation = true
                isOnceLocationLatest = true
                isLocationCacheEnable = false
                isMockEnable = false
                isOffset = true
                isNeedAddress = false
                httpTimeOut = 15000
            })
            locator.setLocationListener { location -> handler.post {
                if (pending == null) return@post
                if (location == null || location.errorCode != 0 || location.isMock || location.coordType != AMapLocation.COORD_TYPE_GCJ02) {
                    finish(null, "LOCATION_UNAVAILABLE")
                } else finish(mapOf(
                    "latitude" to location.latitude, "longitude" to location.longitude,
                    "accuracyMeters" to location.accuracy.toDouble(), "capturedAt" to location.time,
                    "coordinateSystem" to "GCJ02", "mocked" to location.isMock
                ), null)
            } }
            locator.startLocation()
        } catch (_: Exception) { finish(null, "LOCATION_UNAVAILABLE") }
    }
    private fun finish(value: Map<String, Any>?, error: String?) {
        val result = pending ?: return
        pending = null
        handler.removeCallbacks(timeout)
        client?.stopLocation(); client?.onDestroy(); client = null
        if (error == null) result.success(value) else result.error(error, "无法取得有效定位，请检查权限和定位开关后重试", null)
    }
    fun dispose() { finish(null, "LOCATION_CANCELLED") }
}
