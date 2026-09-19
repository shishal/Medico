import '../../../core/supabase/tables.dart';

/// Result of [RpcFunctions.claimActiveDevice].
class ClaimActiveDeviceResult {
  const ClaimActiveDeviceResult({
    required this.ok,
    required this.suspended,
    required this.justSuspended,
    required this.distinctDeviceCount,
  });

  final bool ok;
  final bool suspended;

  /// True when this claim was the 3rd unique device that set suspension.
  final bool justSuspended;
  final int distinctDeviceCount;

  factory ClaimActiveDeviceResult.fromJson(Map<String, dynamic> json) {
    return ClaimActiveDeviceResult(
      ok: json[ClaimActiveDeviceJson.ok] as bool? ?? false,
      suspended: json[ClaimActiveDeviceJson.suspended] as bool? ?? false,
      justSuspended:
          json[ClaimActiveDeviceJson.justSuspended] as bool? ?? false,
      distinctDeviceCount:
          (json[ClaimActiveDeviceJson.distinctDeviceCount] as num?)?.toInt() ??
          0,
    );
  }
}

/// User-facing copy for device / plan-sharing enforcement.
abstract final class DeviceSessionMessages {
  static const signedInElsewhere =
      'This account is signed in on another device.';

  static const planSuspended =
      'Your Pro access was paused because this account was used on too many '
      'devices. Contact support to restore it.';
}
