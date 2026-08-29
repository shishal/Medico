import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/data/auth_repository.dart';
import '../../../profile/presentation/providers/user_profile_provider.dart';
import '../../domain/watermark_identity.dart';

part 'watermark_label_provider.g.dart';

/// Identity tiled over question content. Email comes from Auth (always
/// present when signed in); name/phone come from `profiles` when set.
///
/// Watches [userProfileProvider] as [AsyncValue] so a profile load/error
/// still leaves the email watermark visible.
@riverpod
String watermarkLabel(Ref ref) {
  final email = ref.watch(authRepositoryProvider).currentEmail;
  final profile = ref.watch(userProfileProvider).asData?.value;
  return WatermarkIdentity.label(
    fullName: profile?.fullName,
    phone: profile?.phone,
    email: email,
  );
}
