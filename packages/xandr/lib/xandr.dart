import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:xandr/ad_size.dart';
import 'package:xandr_platform_interface/xandr_platform_interface.dart';

XandrPlatform get _platform => XandrPlatform.instance;

/// A class that manages the XandrAD SDK. It can be used to initialize the SDK,
/// without loading ads or other stuff.
class XandrSDKManager {
  static bool _initialized = false;

  /// A method that initializes the XandrAD SDK.
  /// [memberId] is the Xandr member ID.
  /// [publisherId] is the optional Xandr publisher ID.
  /// set [testMode] to true if in a test environment
  static Future<bool> initialize(
    int memberId, {
    int? publisherId,
    bool testMode = false,
  }) async {
    try {
      _initialized = await _platform.init(
        memberId,
        publisherId: publisherId,
        testMode: testMode,
      );
      debugPrint('XandrSDKManager.initialize >> : $_initialized');
    } catch (e) {
      debugPrint('XandrSDKManager.initialize Error >> : $e');
      _initialized = false;
    }

    return _initialized;
  }

  /// A method that checks if the XandrAD SDK is initialized.
  static bool get initialized => _initialized;
}

/// A controller for managing Xandr functionality.
class XandrController {
  /// Resets XandrController instance
  Future<void> resetController() async {
    await _platform.resetController();
  }

  /// loads an ad.
  Future<bool> loadAd(int widgetId) async {
    debugPrint('loadAd');
    return _platform.loadAd(widgetId);
  }

  /// loads an interstitial ad.
  Future<bool> loadInterstitialAd({
    String? placementID,
    String? inventoryCode,
    CustomKeywords? customKeywords,
  }) async {
    debugPrint('loadInterstitialAd');
    assert(
      placementID != null || inventoryCode != null,
      'placementID or inventoryCode must not be null',
    );
    return _platform.loadInterstitialAd(
      placementID,
      inventoryCode,
      customKeywords,
    );
  }

  /// shows an interstitial ad.
  Future<bool> showInterstitialAd({Duration? autoDismissDelay}) async {
    debugPrint('showInterstitialAd');
    return _platform.showInterstitialAd(autoDismissDelay);
  }

  /// Sets the autoRefreshInterval value of a banner view
  ///
  /// [duration] is the updated duration of autoRefreshInterval
  /// [inventoryCode] is the optional banner inventory code
  /// [placementID] is the optional banner placement ID
  /// At least one of [inventoryCode] or [placementID] must be filled
  /// to identify the banner
  Future<bool> setAutoRefreshInterval({
    required Duration duration,
    String? inventoryCode,
    String? placementID,
  }) {
    assert(
      placementID != null || inventoryCode != null,
      'placementID or inventoryCode must not be null',
    );
    assert(
      (placementID != null && inventoryCode == null) ||
          (placementID == null && inventoryCode != null),
      'only one of placementID and inventoryCode can be set',
    );
    debugPrint(
      '''setAutoRefreshInterval: ${inventoryCode ?? placementID} to ${duration.inSeconds} seconds''',
    );

    return _platform.setAutoRefreshInterval(
      duration.inSeconds,
      inventoryCode,
      placementID,
    );
  }
}

/// The controller for handling multi ad requests.
class MultiAdRequestController extends XandrController {
  /// Controller for handling multi ad requests.
  ///
  /// This controller is responsible for managing multiple ad requests
  /// and coordinating with the XandrController.
  MultiAdRequestController() : super();

  String? _multiAdRequestID;

  /// Returns the request ID associated with the multi-ad request.
  /// If no request ID is available, it returns `null`.
  String? get requestId => _multiAdRequestID;

  /// Initializes the Xandr library.
  ///
  /// Returns a [Future] that completes with a [bool] value indicating whether
  /// the initialization was successful.
  Future<bool> init() async {
    _multiAdRequestID = await _platform.initMultiAdRequest();
    final result = _multiAdRequestID != null;
    return result;
  }

  /// A method that returns true if the multi ad request ID is initialized.
  bool get initialized => _multiAdRequestID != null;

  /// Disposes the resources used by this object.
  ///
  /// This method should be called when the object is no longer needed to
  /// release any resources it holds.
  Future<void> dispose() async {
    await super.resetController();
    if (initialized) {
      await _platform.disposeMultiAdRequest(_multiAdRequestID!);
    }
  }

  /// Loads ads asynchronously.
  ///
  /// Returns a [Future] that completes with a [bool] value indicating whether
  /// the ads were successfully loaded.
  Future<bool> loadAds() async {
    assert(initialized, 'multiAdRequestID must be initialized');
    return _platform.loadAdsForMultiAdRequest(_multiAdRequestID!);
  }
}
