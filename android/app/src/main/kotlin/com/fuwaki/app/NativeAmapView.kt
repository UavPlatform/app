package com.fuwaki.app

import android.app.Activity
import android.app.Application
import android.content.Context
import android.os.Bundle
import android.view.View
import com.amap.api.maps.AMap
import com.amap.api.maps.AMapUtils
import com.amap.api.maps.CoordinateConverter
import com.amap.api.maps.model.Polyline
import com.amap.api.maps.model.PolylineOptions
import com.amap.api.maps.CameraUpdateFactory
import com.amap.api.maps.MapView
import com.amap.api.maps.MapsInitializer
import com.amap.api.maps.model.BitmapDescriptorFactory
import com.amap.api.maps.model.LatLng
import com.amap.api.maps.model.LatLngBounds
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
    private var aircraftMarker: Marker? = null
    private var trackLines = emptyList<Polyline>()
    private var lastTracks = emptyList<List<LatLng>>()
    private val orderMarkers = mutableMapOf<String, Marker>()
    private var lastOrderMarkers: List<*> = emptyList<Any>()
    private var mapReady = false
    private var pendingFit: (() -> Unit)? = null
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
        map.uiSettings.isZoomGesturesEnabled = true
        map.uiSettings.isScrollGesturesEnabled = true
        map.uiSettings.isRotateGesturesEnabled = false
        map.uiSettings.isTiltGesturesEnabled = false
        map.uiSettings.isScaleControlsEnabled = true
        map.setOnMapLoadedListener {
            if (!disposed) {
                mapReady = true
                pendingFit?.invoke()
                pendingFit = null
            }
        }
        map.setOnMapClickListener { point ->
            if (!disposed) channel.invokeMethod("tap", mapOf("latitude" to point.latitude, "longitude" to point.longitude))
        }
        map.setOnMarkerClickListener { marker ->
            val id = orderMarkers.entries.firstOrNull { it.value == marker }?.key
            if (id != null && !disposed) {
                channel.invokeMethod("orderMarkerTap", id)
                true
            } else false
        }
        applyState(args)
        mapPoint(args["center"], args["centerIsGps"] == true)?.let {
            map.moveCamera(CameraUpdateFactory.newLatLngZoom(it, (args["zoom"] as? Number)?.toFloat() ?: 16f))
        }
        channel.setMethodCallHandler { call, result ->
            if (disposed) { result.error("DISPOSED", "地图已关闭", null); return@setMethodCallHandler }
            try {
                when (call.method) {
                    "update" -> { applyState(call.arguments as? Map<*, *> ?: emptyMap<Any, Any>()); result.success(null) }
                    "fit" -> {
                        val values = call.arguments as? Map<*, *>
                        val points = (values?.get("points") as? List<*>)?.mapNotNull { mapPoint(it, false) } ?: emptyList()
                        val density = activity.resources.displayMetrics.density
                        val bottom = ((values?.get("bottomInset") as? Number)?.toFloat() ?: 0f) * density
                        val fit: () -> Unit = {
                            if (!disposed && points.isNotEmpty()) {
                                try {
                                    val bounds = LatLngBounds.Builder()
                                    points.forEach { bounds.include(it) }
                                    map.animateCamera(CameraUpdateFactory.newLatLngBoundsRect(bounds.build(),
                                        (32 * density).toInt(), (32 * density).toInt(), (72 * density).toInt(), bottom.toInt()))
                                } catch (_: Exception) {
                                    map.animateCamera(CameraUpdateFactory.newLatLngZoom(points.first(), 14f))
                                }
                            }
                        }
                        if (mapReady) view.post { fit() } else pendingFit = fit
                        result.success(null)
                    }
                    "move" -> {
                        val values = call.arguments as? Map<*, *>
                        mapPoint(values?.get("center"), values?.get("centerIsGps") == true)?.let {
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

    private fun mapPoint(value: Any?, gps: Boolean): LatLng? {
        val p = point(value) ?: return null
        if (!p.latitude.isFinite() || !p.longitude.isFinite() || p.latitude !in -90.0..90.0 || p.longitude !in -180.0..180.0) return null
        return if (gps) CoordinateConverter(activity).from(CoordinateConverter.CoordType.GPS).coord(p).convert() else p
    }

    private fun updateOrderMarkers(values: List<*>) {
        if (values == lastOrderMarkers) return
        lastOrderMarkers = values
        val ids = mutableSetOf<String>()
        for (raw in values) {
            val entry = raw as? Map<*, *> ?: continue
            val id = entry["id"] as? String ?: continue
            val position = mapPoint(entry["point"], false) ?: continue
            ids.add(id)
            val label = entry["label"] as? String ?: "订单"
            val icon = OrderMapMarkerRenderer.icon(label, entry["selected"] == true,
                activity.resources.displayMetrics.density)
            val marker = orderMarkers[id]
            if (marker != null) {
                marker.position = position
                marker.title = label
                marker.setIcon(icon)
                marker.zIndex = if (entry["selected"] == true) 20f else 10f
            } else {
                orderMarkers[id] = map.addMarker(MarkerOptions().position(position).title(label)
                    .icon(icon).anchor(.5f, 58f / 76f).zIndex(if (entry["selected"] == true) 20f else 10f))
            }
        }
        val removed = orderMarkers.keys.filter { it !in ids }
        removed.forEach { orderMarkers.remove(it)?.remove() }
    }

    private fun applyState(values: Map<*, *>) {
        updateOrderMarkers(values["orderMarkers"] as? List<*> ?: emptyList<Any>())
        val type = if (values["satellite"] == true) AMap.MAP_TYPE_SATELLITE
            else if (values["dark"] == true) AMap.MAP_TYPE_NIGHT else AMap.MAP_TYPE_NORMAL
        if (map.mapType != type) map.mapType = type
        val gps = values["aircraftCoordinatesAreGps"] == true
        aircraftMarker = updateMarker(aircraftMarker, mapPoint(values["aircraft"], gps), "最后收到的飞机位置", BitmapDescriptorFactory.HUE_AZURE)
        val aircraft = mapPoint(values["aircraft"], gps)
        val destination = point(values["destination"])
        val remaining = if (aircraft != null && destination != null) AMapUtils.calculateLineDistance(aircraft, destination).toDouble() else null
        channel.invokeMethod("remainingDistance", remaining)
        val tracks = (values["tracks"] as? List<*>)?.mapNotNull { segment ->
            (segment as? List<*>)?.mapNotNull { mapPoint(it, gps) }?.takeIf { it.size > 1 }
        } ?: emptyList()
        if (tracks != lastTracks) {
            trackLines.forEach { it.remove() }
            trackLines = tracks.map { map.addPolyline(PolylineOptions().addAll(it).width(7f).color(0xff1976d2.toInt())) }
            lastTracks = tracks
        }
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
        pendingFit = null
        orderMarkers.clear()
        lastOrderMarkers = emptyList<Any>()
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
