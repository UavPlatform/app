package com.fuwaki.app

import android.app.Activity
import android.app.Application
import android.content.Context
import android.os.Bundle
import android.view.View
import com.amap.api.maps.AMap
import com.amap.api.maps.CameraUpdateFactory
import com.amap.api.maps.MapView
import com.amap.api.maps.MapsInitializer
import com.amap.api.maps.model.BitmapDescriptorFactory
import com.amap.api.maps.model.LatLng
import com.amap.api.maps.model.Marker
import com.amap.api.maps.model.MarkerOptions
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class NativeAmapFactory(private val activity: Activity, private val messenger: BinaryMessenger) :
    PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView =
        NativeAmapView(activity, messenger, viewId, args as? Map<*, *> ?: emptyMap<Any, Any>())
}

/** A view owns its markers/channel and releases its renderer on disposal. */
private class NativeAmapView(
    private val activity: Activity, messenger: BinaryMessenger, viewId: Int, args: Map<*, *>
) : PlatformView, Application.ActivityLifecycleCallbacks {
    private val channel = MethodChannel(messenger, "com.fuwaki.app/amap/$viewId")
    private val view: MapView
    private val map: AMap
    private var startMarker: Marker? = null
    private var destinationMarker: Marker? = null
    private var disposed = false

    init {
        val key = args["apiKey"] as? String ?: ""
        require(key.isNotBlank()) { "地图 Key 为空" }
        MapsInitializer.updatePrivacyShow(activity, true, true)
        MapsInitializer.updatePrivacyAgree(activity, true)
        MapsInitializer.setApiKey(key)
        view = MapView(activity)
        view.onCreate(Bundle())
        map = view.map
        map.uiSettings.isZoomControlsEnabled = false
        map.uiSettings.isRotateGesturesEnabled = false
        map.uiSettings.isTiltGesturesEnabled = false
        map.uiSettings.isScaleControlsEnabled = true
        map.setOnMapClickListener { point ->
            if (!disposed) channel.invokeMethod("tap", mapOf("latitude" to point.latitude, "longitude" to point.longitude))
        }
        applyState(args)
        point(args["center"])?.let {
            map.moveCamera(CameraUpdateFactory.newLatLngZoom(it, (args["zoom"] as? Number)?.toFloat() ?: 16f))
        }
        channel.setMethodCallHandler { call, result ->
            if (disposed) { result.error("DISPOSED", "地图已关闭", null); return@setMethodCallHandler }
            try {
                when (call.method) {
                    "update" -> { applyState(call.arguments as? Map<*, *> ?: emptyMap<Any, Any>()); result.success(null) }
                    "move" -> {
                        val values = call.arguments as? Map<*, *>
                        point(values?.get("center"))?.let {
                            map.animateCamera(CameraUpdateFactory.newLatLngZoom(it, (values?.get("zoom") as? Number)?.toFloat() ?: 16f))
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            } catch (error: Exception) { result.error("MAP_ERROR", "地图操作失败", null) }
        }
        activity.application.registerActivityLifecycleCallbacks(this)
        view.onResume()
    }

    private fun point(value: Any?): LatLng? {
        val values = value as? Map<*, *> ?: return null
        val lat = (values["latitude"] as? Number)?.toDouble() ?: return null
        val lng = (values["longitude"] as? Number)?.toDouble() ?: return null
        return LatLng(lat, lng)
    }

    private fun applyState(values: Map<*, *>) {
        val type = if (values["satellite"] == true) AMap.MAP_TYPE_SATELLITE
            else if (values["dark"] == true) AMap.MAP_TYPE_NIGHT else AMap.MAP_TYPE_NORMAL
        if (map.mapType != type) map.mapType = type
        startMarker = updateMarker(startMarker, point(values["start"]), "起吊点", BitmapDescriptorFactory.HUE_GREEN)
        destinationMarker = updateMarker(destinationMarker, point(values["destination"]), "卸货点", BitmapDescriptorFactory.HUE_ORANGE)
    }

    private fun updateMarker(marker: Marker?, position: LatLng?, title: String, hue: Float): Marker? {
        if (position == null) { marker?.remove(); return null }
        if (marker != null) {
            if (marker.position != position) marker.position = position
            return marker
        }
        return map.addMarker(MarkerOptions().position(position).title(title)
            .icon(BitmapDescriptorFactory.defaultMarker(hue)))
    }

    override fun getView(): View = view
    override fun dispose() {
        if (disposed) return
        disposed = true
        channel.setMethodCallHandler(null)
        activity.application.unregisterActivityLifecycleCallbacks(this)
        view.onPause()
        view.onDestroy()
    }
    override fun onActivityResumed(owner: Activity) { if (owner === activity && !disposed) view.onResume() }
    override fun onActivityPaused(owner: Activity) { if (owner === activity && !disposed) view.onPause() }
    override fun onActivitySaveInstanceState(owner: Activity, state: Bundle) { if (owner === activity && !disposed) view.onSaveInstanceState(state) }
    override fun onActivityDestroyed(owner: Activity) { if (owner === activity) dispose() }
    override fun onActivityCreated(owner: Activity, state: Bundle?) {}
    override fun onActivityStarted(owner: Activity) {}
    override fun onActivityStopped(owner: Activity) {}
}
