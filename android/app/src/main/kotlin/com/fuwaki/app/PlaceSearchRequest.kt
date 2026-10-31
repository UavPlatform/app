package com.fuwaki.app

import android.app.Activity
import android.os.Handler
import android.os.Looper
import com.amap.api.services.core.AMapException
import com.amap.api.services.core.LatLonPoint
import com.amap.api.services.core.PoiItem
import com.amap.api.services.core.ServiceSettings
import com.amap.api.services.poisearch.PoiResult
import com.amap.api.services.poisearch.PoiSearch
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** 高德 POI 关键字搜索（Android SDK）：选点页用搜索结果定位，不经过后端。 */
class PlaceSearchRequest(private val activity: Activity) {
    companion object {
        const val CHANNEL = "com.fuwaki.app/place_search"
        private const val TIMEOUT_MS = 15000L
    }

    private val handler = Handler(Looper.getMainLooper())

    /** 每次检索递增；回调只对最新一次生效，过期结果直接丢弃。 */
    private var generation = 0
    private var pending: MethodChannel.Result? = null
    private var pendingGeneration = 0
    private val timeout = Runnable {
        if (pending != null) finish(pendingGeneration, null, "SEARCH_TIMEOUT", "搜索超时，请重试", null)
    }

    fun search(call: MethodCall, result: MethodChannel.Result) {
        val key = call.argument<String>("key")?.trim().orEmpty()
        val keyword = call.argument<String>("keyword")?.trim().orEmpty()
        if (key.isEmpty()) {
            result.error("SEARCH_UNAVAILABLE", "地图配置不可用，无法搜索", null)
            return
        }
        if (keyword.isEmpty()) {
            result.error("SEARCH_KEYWORD_EMPTY", "请输入搜索关键词", null)
            return
        }
        // 取消 = 作废旧代次：递增 generation 使在途 SDK 回调在 finish 中丢弃；
        // 同时对旧 Result 回 SEARCH_CANCELLED（MethodChannel 要求每个 Result 恰好回复一次）。
        // Dart 侧另有 _searchSeq，两边都按代次丢弃过期结果。
        pending?.let { previous ->
            pending = null
            previous.error("SEARCH_CANCELLED", "搜索已取消", null)
        }
        handler.removeCallbacks(timeout)
        val current = ++generation
        pending = result
        pendingGeneration = current
        handler.postDelayed(timeout, TIMEOUT_MS)
        try {
            // POI 检索与地图/定位共用同一个 Android SDK key；隐私合规必须在任一检索前声明。
            ServiceSettings.updatePrivacyShow(activity, true, true)
            ServiceSettings.updatePrivacyAgree(activity, true)
            ServiceSettings.getInstance().setApiKey(key)
            start(call, keyword, current)
        } catch (error: Exception) {
            finish(current, null, "SEARCH_FAILED", "搜索失败，请稍后重试", null)
        }
    }

    private fun start(call: MethodCall, keyword: String, current: Int) {
        val city = call.argument<String>("city")?.trim().orEmpty()
        val limit = (call.argument<Int>("limit") ?: 20).coerceIn(1, 25)
        val center = call.argument<Map<*, *>>("center")
        val latitude = (center?.get("latitude") as? Number)?.toDouble()
        val longitude = (center?.get("longitude") as? Number)?.toDouble()
        val query = PoiSearch.Query(keyword, "", city).apply {
            pageSize = limit
            // 城市只作为排序偏好，不限制行政区：跨城选点仍可搜到结果。
            cityLimit = false
            if (latitude != null && longitude != null && latitude.isFinite() && longitude.isFinite() &&
                latitude in -90.0..90.0 && longitude in -180.0..180.0
            ) {
                // 按定位坐标距离排序（非相机中心；以后可改为读相机），附近地点优先；
                // 不加检索半径，避免跨城搜索无结果。
                setLocation(LatLonPoint(latitude, longitude))
                setDistanceSort(true)
            }
        }
        val search = PoiSearch(activity, query)
        search.setOnPoiSearchListener(object : PoiSearch.OnPoiSearchListener {
            override fun onPoiSearched(poiResult: PoiResult?, code: Int) {
                if (code != AMapException.CODE_AMAP_SUCCESS || poiResult == null) {
                    finish(current, null, "SEARCH_FAILED", messageFor(code), code)
                    return
                }
                finish(current, poiResult.pois.orEmpty().mapNotNull { item -> toMap(item) }, null, null, null)
            }

            override fun onPoiItemSearched(item: PoiItem?, code: Int) = Unit
        })
        search.searchPOIAsyn()
    }

    private fun toMap(item: PoiItem): Map<String, Any?>? {
        val point = item.latLonPoint ?: return null
        if (!point.latitude.isFinite() || !point.longitude.isFinite()) return null
        return mapOf(
            "id" to item.poiId.orEmpty(),
            "name" to item.title.orEmpty(),
            "address" to item.snippet.orEmpty(),
            "district" to item.adName.orEmpty(),
            "latitude" to point.latitude,
            "longitude" to point.longitude,
            "distance" to item.distance,
        )
    }

    /**
     * 高德回调可能在子线程：generation 检查与领取 pending 必须整段在主线程串行，
     * 避免 TOCTOU / MethodChannel double-reply（两个回调都通过检查后再各自 reply）。
     */
    private fun finish(
        current: Int,
        payload: Any?,
        errorCode: String?,
        errorMessage: String?,
        amapCode: Int?,
    ) {
        handler.post {
            if (current != pendingGeneration) return@post
            val target = pending ?: return@post
            pending = null
            handler.removeCallbacks(timeout)
            if (errorCode == null) target.success(payload)
            else target.error(errorCode, errorMessage, amapCode)
        }
    }

    private fun messageFor(code: Int): String = when (code) {
        AMapException.CODE_AMAP_INVALID_USER_KEY, AMapException.CODE_AMAP_USER_KEY_RECYCLED -> "地图 Key 无效"
        AMapException.CODE_AMAP_DAILY_QUERY_OVER_LIMIT -> "今日搜索次数已达上限"
        AMapException.CODE_AMAP_ACCESS_TOO_FREQUENT -> "搜索过于频繁，请稍后重试"
        AMapException.CODE_AMAP_CLIENT_NETWORK_EXCEPTION,
        AMapException.CODE_AMAP_CLIENT_SOCKET_TIMEOUT_EXCEPTION,
        AMapException.CODE_AMAP_CLIENT_UNKNOWHOST_EXCEPTION -> "网络不可用，请检查网络后重试"
        else -> "搜索失败，请稍后重试"
    }

    fun dispose() {
        // 作废当前代次，旧回调即使已入队也会在 finish 中丢弃。
        val target = pending ?: return
        pending = null
        generation++
        handler.removeCallbacks(timeout)
        target.error("SEARCH_CANCELLED", "搜索已取消", null)
    }
}
