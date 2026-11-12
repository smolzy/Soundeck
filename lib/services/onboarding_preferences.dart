import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPreferences {
  static const _guestModeKey = 'guest_mode_selected';
  static const _syncOfferPrefix = 'sync_offer_';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<bool> hasChosenGuestMode() async {
    return await _preferences.getBool(_guestModeKey) ?? false;
  }

  Future<void> chooseGuestMode() {
    return _preferences.setBool(_guestModeKey, true);
  }

  Future<bool> hasBeenOfferedSync(String userId) async {
    return await _preferences.getBool('$_syncOfferPrefix$userId') ?? false;
  }

  Future<void> markSyncOffered(String userId) {
    return _preferences.setBool('$_syncOfferPrefix$userId', true);
  }
}
