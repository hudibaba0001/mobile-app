import 'package:mockito/annotations.dart';
import 'package:myapp/services/supabase_auth_service.dart';
import 'package:myapp/services/profile_service.dart';

import 'package:myapp/services/holiday_service.dart';

@GenerateNiceMocks([MockSpec<SupabaseAuthService>(), MockSpec<ProfileService>(), MockSpec<HolidayService>()])
void main() {}
