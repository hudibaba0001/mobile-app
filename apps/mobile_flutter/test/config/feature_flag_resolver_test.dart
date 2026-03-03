import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myapp/config/feature_flag_resolver.dart';
import 'package:myapp/config/feature_flags.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'local override true resolves true, removed override falls back to default',
      () async {
    SharedPreferences.setMockInitialValues({
      FeatureFlagResolver.useTimeBalanceAggregateRpcKey: true,
    });

    final resolver = FeatureFlagResolver();

    expect(await resolver.resolveUseTimeBalanceAggregateRpc(), isTrue);

    await resolver.setLocalAggregateRpcOverride(null);

    expect(await resolver.getLocalAggregateRpcOverride(), isNull);
    expect(
      await resolver.resolveUseTimeBalanceAggregateRpc(),
      FeatureFlags.useTimeBalanceAggregateRpc,
    );
    expect(FeatureFlags.useTimeBalanceAggregateRpc, isFalse);
  });
}
