# AMapLocationClient initializes this SDK's mini mode (product ID 12).
# That mode skips the optional soft RTK locator branch.
-dontwarn com.amap.ams.gnss.GnssSoftLocator

# Tencent's native libraries resolve Java classes and members by name.
-keep class com.tencent.** { *; }

# AMap's native map renderer and the bundled location/search SDK.
-keep class com.amap.api.maps.** { *; }
-keep class com.autonavi.** { *; }
-keep class com.amap.api.trace.** { *; }
-keep class com.amap.api.location.** { *; }
-keep class com.amap.api.fence.** { *; }
-keep class com.amap.api.services.** { *; }
