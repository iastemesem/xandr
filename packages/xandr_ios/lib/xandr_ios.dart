import 'dart:async';
import 'dart:math';

import 'package:xandr_ios/src/messages.g.dart' as messages;
import 'package:xandr_platform_interface/xandr_platform_interface.dart';

extension on messages.HostAPIUserId {
  UserId toUserId() {
    switch (source) {
      case messages.HostAPIUserIdSource.criteo:
        return UserId.criteo(userId);
      case messages.HostAPIUserIdSource.theTradeDesk:
        return UserId.theTradeDesk(userId);
      case messages.HostAPIUserIdSource.netId:
        return UserId.netId(userId);
      case messages.HostAPIUserIdSource.liveramp:
        return UserId.liveramp(userId);
      case messages.HostAPIUserIdSource.uid2:
        return UserId.uid2(userId);
    }
  }
}

extension on UserIdSource {
  messages.HostAPIUserIdSource toHostAPIUserIdSource() {
    switch (this) {
      case UserIdSource.criteo:
        return messages.HostAPIUserIdSource.criteo;
      case UserIdSource.theTradeDesk:
        return messages.HostAPIUserIdSource.theTradeDesk;
      case UserIdSource.netId:
        return messages.HostAPIUserIdSource.netId;
      case UserIdSource.liveramp:
        return messages.HostAPIUserIdSource.liveramp;
      case UserIdSource.uid2:
        return messages.HostAPIUserIdSource.uid2;
    }
  }
}

extension on UserId {
  messages.HostAPIUserId toHostAPIUserId() {
    return messages.HostAPIUserId(
      userId: userId,
      source: source.toHostAPIUserIdSource(),
    );
  }
}

/// The iOS implementation of [XandrPlatform].
class XandrIOS extends XandrPlatform {
  final messages.XandrHostApi _api = messages.XandrHostApi();

  /// Registers this class as the default instance of [XandrPlatform]
  static void registerWith() {
    XandrPlatform.instance = XandrIOS();
  }

  @override
  Future<bool> init(
    int memberId, {
    int? publisherId,
    bool testMode = false,
  }) async {
    return _api.initXandrSdk(
      memberId: memberId,
      publisherId: publisherId,
      testMode: testMode,
    );
  }

  @override
  Future<void> resetController() async {
    return _api.resetController();
  }

  @override
  Future<bool> loadInterstitialAd(
    String? placementID,
    String? inventoryCode,
    CustomKeywords? customKeywords,
  ) async {
    final rng = Random();
    final widgetId = rng.nextInt(1000);
    return _api.loadInterstitialAd(
      widgetId: widgetId,
      placementID: placementID,
      inventoryCode: inventoryCode,
      customKeywords: customKeywords,
    );
  }

  @override
  Future<bool> showInterstitialAd(Duration? autoDismissDelay) {
    return _api.showInterstitialAd(
      autoDismissDelay: autoDismissDelay?.inSeconds,
    );
  }

  @override
  Future<void> setPublisherUserId(String publisherUserId) {
    return _api.setPublisherUserId(publisherUserId);
  }

  @override
  Future<String> getPublisherUserId() {
    return _api.getPublisherUserId();
  }

  @override
  Future<void> setUserIds(List<UserId> userIds) {
    return _api.setUserIds(
      userIds.map((uId) => uId.toHostAPIUserId()).toList(),
    );
  }

  @override
  Future<List<UserId>> getUserIds() async {
    final userIds = await _api.getUserIds();
    return userIds.nonNulls.map((uId) => uId.toUserId()).toList();
  }

  @override
  Future<String> initMultiAdRequest() {
    return _api.initMultiAdRequest();
  }

  @override
  Future<void> disposeMultiAdRequest(String multiAdRequestID) {
    return _api.disposeMultiAdRequest(multiAdRequestID);
  }

  @override
  Future<bool> loadAdsForMultiAdRequest(String multiAdRequestID) {
    return _api.loadAdsForMultiAdRequest(multiAdRequestID);
  }

  @override
  Future<bool> loadAd(int widgetId) async {
    return _api.loadAd(
      widgetId: widgetId,
    );
  }

  @override
  Future<void> setGDPRConsentRequired(bool isConsentRequired) {
    return _api.setGDPRConsentRequired(isConsentRequired);
  }

  @override
  Future<void> setGDPRConsentString(String consentString) {
    return _api.setGDPRConsentString(consentString);
  }

  @override
  Future<void> setGDPRPurposeConsents(String purposeConsents) {
    return _api.setGDPRPurposeConsents(purposeConsents);
  }

  @override
  Future<bool> setAutoRefreshInterval(
    int autoRefreshIntervalInSeconds,
    String? inventoryCode,
    String? placementID,
  ) {
    return _api.setAutoRefreshInterval(
      autoRefreshIntervalInSeconds,
      inventoryCode,
      placementID,
    );
  }
}
