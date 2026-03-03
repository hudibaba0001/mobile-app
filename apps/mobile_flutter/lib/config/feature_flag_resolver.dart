import 'package:shared_preferences/shared_preferences.dart';
import 'feature_flags.dart';

class FeatureFlagResolver {
  static const String useTimeBalanceAggregateRpcKey =
      'ff_use_time_balance_aggregate_rpc';

  final Future<SharedPreferences> Function() _prefsFactory;

  FeatureFlagResolver({
    Future<SharedPreferences> Function()? prefsFactory,
  }) : _prefsFactory = prefsFactory ?? SharedPreferences.getInstance;

  Future<bool?> getLocalAggregateRpcOverride() async {
    final prefs = await _prefsFactory();
    if (!prefs.containsKey(useTimeBalanceAggregateRpcKey)) {
      return null;
    }
    return prefs.getBool(useTimeBalanceAggregateRpcKey);
  }

  Future<void> setLocalAggregateRpcOverride(bool? value) async {
    final prefs = await _prefsFactory();
    if (value == null) {
      await prefs.remove(useTimeBalanceAggregateRpcKey);
      return;
    }
    await prefs.setBool(useTimeBalanceAggregateRpcKey, value);
  }

  Future<bool> resolveUseTimeBalanceAggregateRpc() async {
    final local = await getLocalAggregateRpcOverride();
    if (local != null) {
      return local;
    }

    return FeatureFlags.useTimeBalanceAggregateRpc;
  }
}
