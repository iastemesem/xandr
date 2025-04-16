//
//  FlutterState.swift
//  xandr_ios
//
//  Created by markus korn on 13.05.24.
//

import AppNexusSDK
import Flutter
import Foundation

private func logResult(_ result: Any?) {
  logger
    .debug(
      message: "flutter api: we got a result back from the flutter api \(String(describing: result))"
    )
}

public class FlutterState {
  public var isInitialized: Completer<Bool> = .init()
  public var memberId: Int!
  public var publisherId: Int?
  private var flutterBannerAdviews: [Int64: XandrBanner] = [:]

  private var binaryMessenger: FlutterBinaryMessenger

  init(binaryMessenger: FlutterBinaryMessenger) {
    self.binaryMessenger = binaryMessenger
  }

  func startListening(api: XandrHostApi) {
    XandrHostApiSetup.setUp(binaryMessenger: binaryMessenger, api: api)
  }

  func stopListening() {
    XandrHostApiSetup.setUp(binaryMessenger: binaryMessenger, api: nil)
  }

  func flushBannerAdViewList() {
    flutterBannerAdviews.removeAll()
  }

  public func setIsInitialized(success: Bool) {
    isInitialized.complete(success)
  }

  public func setIsInitializedCompletionHandler(handler: @escaping (Bool) -> Void) {
    isInitialized.invokeOnCompletion(handler)
  }

  func getOrCreateXandrBanner(frame: CGRect, id: Int64, args: Any?) -> XandrBanner {
    if flutterBannerAdviews[id] == nil {
      logger.debug(message: "Create new XandrBanner for widgetId=\(id)")
      flutterBannerAdviews[id] = XandrBanner(
        state: self,
        frame: frame,
        viewIdentifier: id,
        args: args,
        binaryMessenger: binaryMessenger
      )
    }

    logger.debug(message: "Return existing XandrBanner for widgetId=\(id)")
    return flutterBannerAdviews[id]!
  }

  func getXandrBanner(id: Int64) throws -> XandrBanner {
    if flutterBannerAdviews[id] != nil {
      logger.debug(message: "Return XandrBanner for widgetId=\(id)")
      return flutterBannerAdviews[id]!
    } else {
      logger.error(message: "XandrBanner for widgetId=\(id) not found!")
      throw XandrPluginError.runtimeError("Unable to find Banner for widgetId=\(id)")
    }
  }

  func getXandrBannerWithCode(inventoryCode: String?, placementID: String?) throws -> XandrBanner {
    for (_, bannerAdView) in flutterBannerAdviews {
      if (inventoryCode != nil && bannerAdView.banner?.inventoryCode == inventoryCode) ||
        (placementID != nil && bannerAdView.banner?.placementId == placementID) {
        logger
          .debug(
            message: "Return XandrBanner for inventoryCode=\(String(describing: inventoryCode)), placementID=\(String(describing: placementID))"
          )
        return bannerAdView
      }
    }
    logger
      .error(
        message: "XandrBanner for inventoryCode=\(String(describing: inventoryCode)), placementID=\(String(describing: placementID)) not found!"
      )
    throw XandrPluginError
      .runtimeError(
        "Unable to find Banner for inventoryCode=\(String(describing: inventoryCode)), placementID=\(String(describing: placementID))"
      )
  }
}
