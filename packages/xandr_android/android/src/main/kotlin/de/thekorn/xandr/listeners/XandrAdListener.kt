package de.thekorn.xandr.listeners

import com.appnexus.opensdk.AdListener
import com.appnexus.opensdk.AdView
import com.appnexus.opensdk.NativeAdResponse
import com.appnexus.opensdk.ResultCode
import com.appnexus.opensdk.utils.JsonUtil
import de.thekorn.xandr.models.ads.BannerAd
import de.thekorn.xandr.models.ads.InterstitialAd
import io.flutter.Log
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import org.json.JSONObject

open class XandrAdListener(
    private var widgetId: Int,
    private var eventSink: EventSink?
) :
    AdListener {
    override fun onAdLoaded(view: AdView?) {
        Log.d(
            "Xandr.BannerView",
            ">>> Ad Loaded, id=${view?.id} widgetId=$widgetId, w=${view?.creativeWidth}," +
                " h=${view?.creativeHeight}"
        )
        if (view != null) {
            val adResponse = view.adResponseInfo
            eventSink?.success(
                mapOf(
                    "event" to "onAdLoaded",
                    "widgetId" to widgetId.toLong(),
                    "width" to view.creativeWidth.toLong(),
                    "height" to view.creativeHeight.toLong(),
                    "creativeId" to adResponse?.creativeId,
                    "adType" to adResponse?.adType.toString(),
                    "tagId" to adResponse?.tagId,
                    "auctionId" to adResponse?.auctionId,
                    "cpm" to adResponse?.cpm,
                    "buyMemberId" to adResponse?.buyMemberId?.toLong()
                )
            );
        } else {
            eventSink?.success(
                mapOf(
                    "event" to "onAdLoadedError",
                    "widgetId" to widgetId.toLong(),
                    "error" to "Unknown error while loading banner ad"
                )
            )
        }
    }

    override fun onAdLoaded(adResponse: NativeAdResponse?) {
        Log.d(
            "Xandr.BannerView",
            ">>> Ad Loaded, NativeAdResponse=$adResponse, title=${adResponse?.title} " +
                "for $widgetId"
        )
        var clickUrl: String? = null
        var customElements: String = ""
        if ((adResponse?.networkIdentifier == NativeAdResponse.Network.APPNEXUS) &&
            (adResponse.nativeElements?.get(NativeAdResponse.NATIVE_ELEMENT_OBJECT)) is JSONObject
        ) {
            val nativeResponseJSON = (
                adResponse.nativeElements
                    [NativeAdResponse.NATIVE_ELEMENT_OBJECT]
                )
                as JSONObject
            clickUrl = JsonUtil.getJSONObject(nativeResponseJSON, "link").getString("url")
            if (clickUrl.isEmpty()) {
                clickUrl =
                    JsonUtil.getJSONObject(nativeResponseJSON, "link").getString("fallback_url")
            }

            customElements = nativeResponseJSON.toString()
            
            Log.d(
                "Xandr.BannerView",
                ">>> Ad Loaded, NativeAdResponse customElements=$customElements"
            )
        }

        if (adResponse != null && clickUrl != null) {
            eventSink?.success(
                mapOf(
                    "event" to "onNativeAdLoaded",
                    "widgetId" to widgetId.toLong(),
                    "title" to adResponse.title,
                    "description" to adResponse.description,
                    "imageUrl" to adResponse.imageUrl,
                    "clickUrl" to clickUrl,
                    "customElements" to customElements
                )
            )
        } else {
            eventSink?.success(
                mapOf(
                    "event" to "onNativeAdLoadedError",
                    "widgetId" to widgetId.toLong(),
                    "error" to "Unknown error while loading native banner ad"
                )
            )
        }
    }

    override fun onAdRequestFailed(p0: AdView?, p1: ResultCode?) {
        Log.d(
            "Xandr.BannerView",
            ">>> Ad Request failed, AdView:p0=$p0 ResultCode:p1=$p1"
        )

        eventSink?.success(
            mapOf(
                "event" to "onAdRequestFailed",
                "widgetId" to widgetId.toLong(),
                "error" to p1.toString()
            )
        )
    }

    override fun onAdExpanded(p0: AdView?) {
        Log.d(
            "Xandr.BannerView",
            ">>> Ad expanded, AdView:p0=$p0"
        )
        eventSink?.success(
            mapOf(
                "event" to "onAdExpanded",
                "widgetId" to widgetId.toLong()
            )
        )
    }

    override fun onAdCollapsed(p0: AdView?) {
        Log.d(
            "Xandr.BannerView",
            ">>> Ad collapsed, AdView:p0=$p0"
        )
        eventSink?.success(
            mapOf(
                "event" to "onAdCollapsed",
                "widgetId" to widgetId.toLong()
            )
        )
    }

    override fun onAdClicked(p0: AdView?) {
        Log.d(
            "Xandr.BannerView",
            ">>> Ad clicked, AdView:p0=$p0"
        )
        eventSink?.success(
            mapOf(
                "event" to "onAdClicked",
                "widgetId" to widgetId.toLong()
            )
        )
    }

    override fun onAdClicked(p0: AdView?, p1: String?) {
        Log.d(
            "Xandr.BannerView",
            ">>> Ad clicked, AdView:p0=$p0 String:p1=$p1"
        )
        p1?.let {
            eventSink?.success(
                mapOf(
                    "event" to "onAdClicked",
                    "widgetId" to widgetId.toLong(),
                    "url" to it
                )
            )
        }
    }

    override fun onLazyAdLoaded(adView: AdView?) {
        Log.d(
            "Xandr.BannerView",
            ">>> Ad lazy loaded, AdView:p0=$adView"
        )
        eventSink?.success(
            mapOf(
                "event" to "onLazyAdLoaded",
                "widgetId" to widgetId.toLong()
            )
        )
    }

    override fun onAdImpression(p0: AdView?) {
        Log.d(
            "Xandr.BannerView",
            ">>> Ad impressions, AdView:p0=$p0"
        )
        eventSink?.success(
            mapOf(
                "event" to "onAdImpression",
                "widgetId" to widgetId.toLong()
            )
        )
    }
}

class XandrInterstitialAdListener(
    widgetId: Long,
    private var interstitialAd: InterstitialAd,
    private var eventSink: EventChannel.EventSink?
) : XandrAdListener(widgetId.toInt(), null) {
    override fun onAdLoaded(view: AdView?) {
        super.onAdLoaded(view)
        if (!interstitialAd.isLoaded.isCompleted) {
            interstitialAd.isLoaded.complete(true)
        }
        Log.d("Xandr.InterstitialView", "onAdLoaded")
    }

    override fun onAdCollapsed(p0: AdView?) {
        super.onAdCollapsed(p0)
        if(!interstitialAd.isClosed.isCompleted){
            interstitialAd.isClosed.complete(true)
        }
        Log.d("Xandr.InterstitialView", "onAdCollapsed")
    }
}

class XandrBannerAdListener(
    widgetId: Long,
    private var banner: BannerAd,
    private var eventSink: EventChannel.EventSink?
) : XandrAdListener(widgetId.toInt(), eventSink) {

    override fun onLazyAdLoaded(adView: AdView?) {
        Log.d(
            "Xandr.BannerView",
            ">>> Ad lazy loaded, AdView:p0=$adView"
        )
        this.banner.loadLazyAd()
        return super.onLazyAdLoaded(adView)
    }
}
