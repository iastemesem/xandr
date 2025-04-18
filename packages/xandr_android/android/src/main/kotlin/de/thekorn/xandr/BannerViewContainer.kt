package de.thekorn.xandr

import android.app.Activity
import android.view.View
import de.thekorn.xandr.listeners.XandrBannerAdListener
import de.thekorn.xandr.models.BannerViewOptions
import de.thekorn.xandr.models.FlutterState
import de.thekorn.xandr.models.ads.BannerAd
import io.flutter.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import kotlinx.coroutines.ExperimentalCoroutinesApi

class BannerViewContainer(
    activity: Activity,
    private var state: FlutterState,
    private var widgetId: Int,
    private val bannerViewOptions: BannerViewOptions?,
    private var messenger: BinaryMessenger
) : PlatformView {
    val banner: BannerAd
    private var eventSink: EventChannel.EventSink? = null
    private val eventChannel = EventChannel(messenger, "xandr_ad_event_channel_$widgetId")
    private val methodChannel = MethodChannel(messenger, "xandr_ad_banner_channel_$widgetId")

    init {
        Log.d(
            "Xandr.BannerViewContainer",
            "Initializing id=$widgetId "
        )

        this.banner = BannerAd(activity, state, widgetId, eventSink).apply {
            if (bannerViewOptions != null) {
                this.configure(bannerViewOptions)
            }
        }

        eventChannel.setStreamHandler(object :
            EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventSink?) {
                eventSink = events
                if (banner.adListener == null) {
                    banner.adListener = XandrBannerAdListener(
                        widgetId.toLong(),
                        banner,
                        eventSink
                    )
                }
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })

        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "loadAd" -> {
                    Log.d("Xandr.BannerViewContainer", "loadAd called")
                    loadAd()
                    result.success(null)
                }
                "dispose" -> {
                    Log.d("Xandr.BannerViewContainer", "dispose called")
                    dispose()
                    result.success(null)
                }
                else -> {
                    Log.d("Xandr.BannerViewContainer", "Unknown method called: ${call.method}")
                    result.notImplemented()
                }
            }
        }
    }

    @OptIn(ExperimentalCoroutinesApi::class)
    override fun getView(): View {
        Log.d(
            "Xandr.BannerViewContainer",
            "getView, widgetId=$widgetId"
        )
        return this.banner
    }

    fun loadAd() {
        this.banner.loadAd()
    }

    override fun dispose() {
        Log.d("Xandr.BannerViewContainer", "Disposing banner $widgetId")
        eventSink = null
        this.banner.adListener = null
        this.banner.destroy()
        state.removeBannerView(widgetId)
    }
}
