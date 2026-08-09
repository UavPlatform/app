package com.fuwaki.app

import android.app.Application
import com.amap.api.location.AMapLocationClient

class MyApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        // 隐私合规必须在 Application.onCreate 中、所有 SDK API 调用之前执行
        AMapLocationClient.updatePrivacyShow(this, true, true)
        AMapLocationClient.updatePrivacyAgree(this, true)
    }
}
