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
import io.flutter.plugin.platform.PlatformView
import kotlinx.coroutines.ExperimentalCoroutinesApi

class BannerViewContainer(
    activity: Activity,
    private var state: FlutterState,
    private var widgetId: Int,
    private val bannerViewOptions: BannerViewOptions?,
    private var messenger: BinaryMessenger,
) : PlatformView {
    val banner: BannerAd
    private var eventSink: EventChannel.EventSink? = null
    private val eventChannel = EventChannel(messenger, "xandr_ad_event_channel_$widgetId")


    init {
        Log.d(
            "Xandr.BannerView",
            "Initializing $activity id=$widgetId " +
                "xandr-initialized=${state.isInitialized} bannerViewOptions=$bannerViewOptions"
        )

        this.banner = BannerAd(activity, state, widgetId, eventSink)

        if (bannerViewOptions != null) {
            this.banner.configure(bannerViewOptions)
        }

        eventChannel.setStreamHandler(object :
            EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventSink?) {
                eventSink = events
                if (banner.adListener == null)
                    banner.adListener = XandrBannerAdListener(
                        widgetId.toLong(),
                        state.flutterApi,
                        banner,
                        eventSink,
                    )
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
    }


    @OptIn(ExperimentalCoroutinesApi::class)
    override fun getView(): View {
        Log.d(
            "Xandr.BannerView",
            "Return view, xandr-initialized=${state.isInitialized.isCompleted}"
        )

        if (bannerViewOptions?.multiAdRequestId == null) {
            state.isInitialized.invokeOnCompletion {
                Log.d(
                    "Xandr.BannerView",
                    "load add, xandr-initialized=${state.isInitialized.getCompleted()}"
                )
                bannerViewOptions?.loadWhenCreated?.let { loadWhenCreated ->
                    if (loadWhenCreated) {
                        loadAd()
                    }
                }
            }
        }

        return this.banner
    }

    fun loadAd() {
        this.banner.loadAd()
    }

    override fun dispose() {
        Log.d("Xandr.BannerView", "Disposing banner $widgetId")
        eventSink = null
        this.banner.destroy()
    }
}
