package de.thekorn.xandr.models.ads

import android.annotation.SuppressLint
import android.app.Activity
import android.app.Application
import android.os.Bundle
import androidx.lifecycle.DefaultLifecycleObserver
import com.appnexus.opensdk.ANClickThroughAction
import com.appnexus.opensdk.BannerAdView
import de.thekorn.xandr.models.BannerViewOptions
import de.thekorn.xandr.models.FlutterState
import de.thekorn.xandr.models.MultiAdRequestRegistry
import io.flutter.Log
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink

@SuppressLint("ViewConstructor")
class BannerAd(
    private var activity: Activity,
    private var state: FlutterState,
    private var widgetId: Int,
    private var eventSink: EventChannel.EventSink?
) : BannerAdView(activity),
    DefaultLifecycleObserver,
    Application.ActivityLifecycleCallbacks {

    private var configured = false

    init {
        activity.application.registerActivityLifecycleCallbacks(this)
    }

    fun configure(bannerViewOptions: BannerViewOptions) {
        bannerViewOptions.let {
            it.adSizes?.let { adSizes ->
                this.adSizes = adSizes
            }

            it.autoRefreshInterval?.let { autoRefreshInterval ->
                this.autoRefreshInterval = autoRefreshInterval
            }

            it.customKeywords?.forEach { kw ->
                kw.value.forEach { value ->
                    this.addCustomKeywords(kw.key, value)
                }
            }

            it.allowNativeDemand?.let { allowNativeDemand ->
                this.allowNativeDemand = allowNativeDemand
            }

            it.nativeAdRendererId?.let { nativeAdRendererId ->
                this.rendererId = nativeAdRendererId
            }

            it.shouldServePSAs?.let { shouldServePSAs ->
                this.shouldServePSAs = shouldServePSAs
            }

            it.clickThroughAction?.let { clickThroughAction ->
                when (clickThroughAction) {
                    "open_device_browser" -> {
                        this.clickThroughAction = ANClickThroughAction.OPEN_DEVICE_BROWSER
                    }

                    "open_sdk_browser" -> {
                        this.clickThroughAction = ANClickThroughAction.OPEN_SDK_BROWSER
                    }

                    "return_url" -> {
                        this.clickThroughAction = ANClickThroughAction.RETURN_URL
                    }
                }
            }
            it.loadsInBackground?.let { loadsInBackground ->
                this.loadsInBackground = loadsInBackground
            }
            it.resizeAdToFitContainer?.let { resizeAdToFitContainer ->
                this.resizeAdToFitContainer = resizeAdToFitContainer
            }
            it.enableLazyLoad?.let { enableLazyLoad ->
                if (enableLazyLoad) {
                    this.enableLazyLoad()
                }
            }
            it.multiAdRequestId?.let { multiAdRequestId ->
                MultiAdRequestRegistry.addAdUnit(multiAdRequestId, this)
            }
        }

        if (state.publisherId != null) {
            this.publisherId = state.publisherId!!
        }

        state.isInitialized.invokeOnCompletion {
            // / need to make sure the sdk is initialized to access the memberId
            // / docs: Note that if both inventory code and placement ID are passed in, the
            //        inventory code will be passed to the server instead of the placement ID.
            bannerViewOptions.let {
                if (it.inventoryCode != null) {
                    Log.d(
                        "Xandr.BannerView",
                        "Xandr is initialized, setting the inventoryCode"
                    )
                    this.setInventoryCodeAndMemberID(state.memberId, it.inventoryCode)
                    configured = true
                } else {
                    Log.d(
                        "Xandr.BannerView",
                        "Xandr is initialized, setting the placementID"
                    )
                    this.placementID = it.placementID
                    configured = true
                }
                Log.d("Xandr.BannerView", "Initializing DONE")
            }
        }
    }

    override fun loadAd(): Boolean {
        if (!configured) {
            Log.e("Xandr.BannerView", "Banner non configurato, skip loadAd()")
            return false
        }

        Log.e(
            "Xandr.BannerView",
            "placementId = ${this.placementID} -- adWidth = ${this.adWidth} -- adHeight = ${this.adHeight} -- inventoryCode = ${this.inventoryCode} -- memberId = ${this.memberID}"
        )
        if ((this.placementID != null || this.inventoryCode != null) &&
            this.adWidth > 0 &&
            this.adHeight > 0
        ) {
            try {
                Log.d("Xandr.BannerView", "loadAd; id=$widgetId")
                return super.loadAd()
            } catch (e: Exception) {
                Log.e("Xandr.BannerView", "loadAd; id=$widgetId", e)
                eventSink?.success(
                    mapOf(
                        "event" to "onAdFailed",
                        "widgetId" to widgetId.toLong(),
                        "error" to e.toString()
                    )
                )
                return false
            }
        } else {
            Log.e("Xandr.BannerView", "Banner non configurato correttamente, skip loadAd()")
            return false
        }
    }

    override fun onActivityResumed(p0: Activity) {
        Log.d("Xandr.BannerView", "activityOnResume")
        this.activityOnResume()
    }

    override fun onActivityPaused(p0: Activity) {
        Log.d("Xandr.BannerView", "activityOnPause")
        this.activityOnPause()
    }

    override fun onActivityDestroyed(p0: Activity) {}
    override fun onActivityCreated(p0: Activity, p1: Bundle?) {}
    override fun onActivityStarted(p0: Activity) {}
    override fun onActivityStopped(p0: Activity) {}
    override fun onActivitySaveInstanceState(p0: Activity, p1: Bundle) {}
}
