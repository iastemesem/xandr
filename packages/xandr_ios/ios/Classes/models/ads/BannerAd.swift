//
//  BannerAd.swift
//  xandr_ios
//
//  Created by markus korn on 14.07.24.
//

import AppNexusSDK
import Flutter
import Foundation

func jsonDump(_ object: [String: Any?]) -> String? {
  // Convert nil values to NSNull
  let sanitizedObject = object.mapValues { $0 ?? NSNull() }

  // Try to serialize to JSON data
  if let jsonData = try? JSONSerialization.data(
    withJSONObject: sanitizedObject,
    options: .prettyPrinted
  ) {
    return String(data: jsonData, encoding: .utf8)
  }

  return nil
}

class XandrBanner: NSObject, FlutterPlatformView, ANBannerAdViewDelegate, FlutterStreamHandler {
    
  public var banner: ANBannerAdView?
  public var state: FlutterState?
  public var viewId: Int64
  private var eventSink: FlutterEventSink?
  private var eventChannel: FlutterEventChannel?
  private var methodChannel: FlutterMethodChannel?

  init(state: FlutterState, frame: CGRect,
       viewIdentifier viewId: Int64,
       args: Any?,
       binaryMessenger messenger: FlutterBinaryMessenger?) {
    
    self.viewId = viewId
    if messenger != nil {
        eventChannel = FlutterEventChannel(name: "xandr_ad_event_channel_\(viewId)", binaryMessenger: messenger!)
        methodChannel = FlutterMethodChannel(name: "xandr_ad_banner_channel_\(viewId)", binaryMessenger: messenger!)
    }
      
    super.init()
    // Do any additional setup after loading the view.
    ANSDKSettings.sharedInstance().enableOMIDOptimization = true
    logger.debug(message: "init banner")
    self.state = state
      
    eventChannel?.setStreamHandler(self)
    methodChannel?.setMethodCallHandler { [weak self] call, result in
        if call.method == "loadAd" {
          self?.loadAd()
            result(nil)
        }
        
        if call.method == "dispose" {
            self?.dispose()
            result(nil)
        }
        
        result(FlutterMethodNotImplemented)
      }

    guard let arguments = args as? [String: Any] else {
      return
    }

    let adSizesArgs = arguments["adSizes"] as? [[String: Int]]
    let customKeywords = arguments["customKeywords"] as? [String: [String]]
    // let layoutHeight = arguments["layoutHeight"] as? Int
    // let layoutWidth = arguments["layoutWidth"] as? Int
    let shouldServePSAs = arguments["shouldServePSAs"] as? Bool ?? false
    // let loadsInBackground = arguments["loadsInBackground"] as? Bool ?? false
    let resizeAdToFitContainer = arguments["resizeAdToFitContainer"] as? Bool ?? false
    let placementID = arguments["placementID"] as? String
    // let memberId = arguments["memberId"] as? String //<--- taken from state
    let inventoryCode = arguments["inventoryCode"] as? String
    let clickThroughAction = arguments["clickThroughAction"] as? String
    let autoRefreshInterval = arguments["autoRefreshInterval"] as? Double ?? 30
    // let resizeWhenLoaded = arguments["resizeWhenLoaded"] as? Bool ?? false
    let allowNativeDemand = arguments["allowNativeDemand"] as? Bool ?? false
    let nativeAdRendererId = arguments["nativeAdRendererId"] as? Int
    // let loadWhenCreated = arguments["loadWhenCreated"] as? Bool ?? false
    let enableLazyLoad = arguments["enableLazyLoad"] as? Bool ?? false
    let multiAdRequestId = arguments["multiAdRequestId"] as? String

    var adSizes: [NSValue] = []
    adSizesArgs?.forEach { size in
      adSizes.append(NSValue(cgSize: CGSize(
        width: size["width"]! as Int,
        height: size["height"]! as Int
      )))
    }

    state.setIsInitializedCompletionHandler { [self] result in
      // Make a banner ad view.
      banner = ANBannerAdView(
        frame: frame,
        memberId: state.memberId!,
        inventoryCode: inventoryCode!
      )
      banner?.delegate = self
      // banner?.appEventDelegate = self
      customKeywords?.forEach { item in
        for value in item.value {
          banner?.addCustomKeyword(withKey: item.key, value: value)
        }
      }
      if state.publisherId != nil {
        banner?.publisherId = state.publisherId!
      }

      banner?.adSizes = adSizes
      banner?.shouldResizeAdToFitContainer = resizeAdToFitContainer
      banner?.autoRefreshInterval = autoRefreshInterval
      banner?.shouldAllowNativeDemand = allowNativeDemand
      banner?.shouldServePublicServiceAnnouncements = shouldServePSAs
      banner?.enableLazyLoad = enableLazyLoad
      if nativeAdRendererId != nil {
        banner?.nativeAdRendererId = nativeAdRendererId!
        logger.debug(message: "using nativeAdRendererId=\(String(describing: nativeAdRendererId))")
      }

      if clickThroughAction != nil {
        switch clickThroughAction {
        case "open_device_browser":
          banner?.clickThroughAction = .openDeviceBrowser
        case "open_sdk_browser":
          banner?.clickThroughAction = .openSDKBrowser
        case "return_url":
          banner?.clickThroughAction = .returnURL
        default:
          banner?.clickThroughAction = .openSDKBrowser
        }
      }

      if inventoryCode != nil {
        banner?.setInventoryCode(inventoryCode, memberId: state.memberId)
      } else {
        banner?.placementId = placementID
      }

      if multiAdRequestId != nil && banner != nil{
        let result = MultiAdRequestRegistry.shared.addAdUnit(multiAdRequestId!, ad: banner!)
        logger.debug(message: "add adUnit result: \(result)")
      } else {
        logger.debug(message: "init banner, load ad...")
        banner?.loadAd()
      }
    }
  }

  func view() -> UIView {
    guard let temp = banner else {
      logger.error(message: "banner is not initialized")
      return UIView()
    }
    return temp
  }

  func loadAd() {
    banner?.loadAd()
  }
    
    func dispose() {
        banner?.delegate = nil
        banner?.removeFromSuperview()
        banner = nil
    }

  public func adDidReceiveAd(_ ad: Any) {
    if ad is ANBannerAdView {
      let a = ad as? ANBannerAdView
      if let info = a?.adResponseInfo {
          eventSink?(
            [
                "event": "onAdLoaded",
                "width": Int(a!.loadedAdSize.width),
                "height": Int((a?.loadedAdSize.height)!),
                "creativeId" : info.creativeId!,
                "adType": info.adType.rawValue,
                "tagId": "",
                "auctionId": info.auctionId!,
                "cpm": info.cpm!.doubleValue,
                "memberId": info.memberId
            ]
          )
      } else {
        logger
          .error(
            message: "BannerAd.adDidRecieveAd: we did not get an adResponseInfo back, got \(String(describing: a))"
          )
      }
    } else {
      logger.error(message: "BannerAd.adDidRecieveAd: unknown \(ad)")
    }
  }

  public func ad(_ loadInstance: Any, didReceiveNativeAd responseInstance: Any) {
    if let nativeAdResponse = responseInstance as? ANNativeAdResponse,
       let title = nativeAdResponse.title, let description = nativeAdResponse.body,
       let imageUrl = nativeAdResponse.mainImageURL,
       let customElements = nativeAdResponse.customElements?["ELEMENT"] as? [String: Any?] {
      let clickUrl = (customElements["link"] as? [String: Any])?["url"] as? String
      let clickFallbackUrl = (customElements["link"] as? [String: Any])?["fallback_url"] as? String

      if clickUrl != nil || clickFallbackUrl != nil {
          eventSink?(
            [
                "event" : "onNativeAdLoaded",
                "viewId" : viewId,
                "title" : title,
                "description" : description,
                "imageUrl" : imageUrl.absoluteString,
                "clicKUrl" : clickUrl ?? clickFallbackUrl ?? "",
                "customElements" : jsonDump(customElements) ?? "{}"
            ]
          )
      } else {
        logger
          .error(
            message: "BannerAd.addidReceiveNativeAd: we did not get a click URL for response, got \(String(describing: responseInstance))"
          )
      }
    } else {
      logger
        .error(
          message: "BannerAd.addidReceiveNativeAd: we did not get an ANNativeAdResponse back, got \(String(describing: responseInstance))"
        )
    }
  }

  func ad(_ ad: Any, requestFailedWithError error: any Error) {
    logger.error(message: "BannerAd.adDidRecieveAd: an error \(error)")
      eventSink?(
        [
            "event" : "onAdLoadedError",
            "error" : error.localizedDescription
        ]
      )
  }

  public func adWasClicked(_ ad: Any, withURL urlString: String) {
    if ad is ANBannerAdView {
      let _ = ad as? ANBannerAdView
        eventSink?(
            [
                "event": "onAdClicked",
                "url" : urlString
            ]
        )
    } else {
      logger.error(message: "BannerAd.adWasClicked: unknown \(ad)")
    }
  }
    
    /// Flutter stream handler methods, used from EventSink and EventChannel
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        result("Hello World!")
    }
}
