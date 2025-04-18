package de.thekorn.xandr.models

import XandrHostApi
import android.app.Activity
import android.content.Context
import de.thekorn.xandr.BannerViewContainer
import de.thekorn.xandr.XandrPlugin
import io.flutter.Log
import io.flutter.plugin.common.BinaryMessenger
import kotlin.properties.Delegates
import kotlinx.coroutines.CompletableDeferred

class FlutterState(var applicationContext: Context, private var binaryMessenger: BinaryMessenger) {
    val isInitialized: CompletableDeferred<Boolean> = CompletableDeferred()

    private val flutterBannerAdViews = mutableMapOf<Int, BannerViewContainer>()

    var memberId by Delegates.notNull<Int>()
    var publisherId: Int? = null

    fun startListening(methodCallHandler: XandrPlugin) {
        XandrHostApi.setUp(this.binaryMessenger, methodCallHandler)
    }

    fun stopListening() {
        XandrHostApi.setUp(this.binaryMessenger, null)
    }

    fun flushBannerAdViewList() {
        this.flutterBannerAdViews.clear()
    }

    fun getOrCreateBannerView(activity: Activity, id: Int, args: Any?): BannerViewContainer {
        Log.d(
            "Xandr.BannerViewFactory",
            "Get or create BannerView with id=$id"
        )
        if (!flutterBannerAdViews.containsKey(id)) {
            Log.d("Xandr.BannerViewFactory", "Create new FlutterBannerAdView for id=$id")
            flutterBannerAdViews[id] = BannerViewContainer(
                activity,
                this,
                id,
                (args as? Map<*, *>)?.toBannerAdViewOptions(),
                this.binaryMessenger
            )
        }
        Log.d("Xandr.BannerViewFactory", "Return existing FlutterBannerAdView for id=$id")
        return flutterBannerAdViews[id]!!
    }

    fun getBannerView(id: Int): BannerViewContainer {
        if (flutterBannerAdViews.containsKey(id)) {
            Log.d("Xandr.BannerViewFactory", "Return XandrBanner for widgetId=$id")
            return flutterBannerAdViews[id]!!
        }
        Log.e("Xandr.BannerViewFactory", "Banner for widgetId=$id not found!")
        throw RuntimeException("Unable to find Banner for widgetId=$id")
    }

    fun getBannerViewWithCode(inventoryCode: String?, placementID: String?): BannerViewContainer {
        for ((_, bannerAdView) in flutterBannerAdViews) {
            if ((inventoryCode != null && inventoryCode == bannerAdView.banner.inventoryCode) ||
                (placementID != null && placementID == bannerAdView.banner.placementID)
            ) {
                Log.d(
                    "Xandr.BannerViewFactory",
                    "Return XandrBanner for inventoryCode=$inventoryCode, placementID=$placementID"
                )
                return bannerAdView
            }
        }
        Log.e(
            "Xandr.BannerViewFactory",
            "Banner for  inventoryCode=$inventoryCode, placementID=$placementID not found!"
        )
        throw RuntimeException(
            "Unable to find Banner for inventoryCode=$inventoryCode, placementID=$placementID"
        )
    }

    fun removeBannerView(id: Int) {
        Log.d("Xandr.BannerViewFactory", "Remove XandrBanner for widgetId=$id")
        if (flutterBannerAdViews.containsKey(id)) {
            Log.d("Xandr.BannerViewFactory", "Remove XandrBanner for widgetId=$id")
            flutterBannerAdViews.remove(id)
        } else {
            Log.e("Xandr.BannerViewFactory", "Banner for widgetId=$id not found!")
        }
    }
}
