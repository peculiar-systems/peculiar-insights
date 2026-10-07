import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:peculiar_insights/gen/peculiar/insights/v1/common.pb.dart"
    as pb;
import "package:peculiar_insights/gen/peculiar/insights/v1/options.pb.dart"
    as pb;

part "consent.freezed.dart";

enum Purpose {
  analytics,
  diagnostics;

  pb.Purpose toProto() => switch (this) {
    Purpose.analytics => pb.Purpose.PURPOSE_ANALYTICS,
    Purpose.diagnostics => pb.Purpose.PURPOSE_DIAGNOSTICS,
  };
}

Purpose? purposeFromProto(pb.Purpose purpose) => switch (purpose) {
  pb.Purpose.PURPOSE_ANALYTICS => Purpose.analytics,
  pb.Purpose.PURPOSE_DIAGNOSTICS => Purpose.diagnostics,
  _ => null,
};

enum Decision { undecided, granted, withdrawn }

@freezed
abstract class PurposeStatus with _$PurposeStatus {
  const PurposeStatus._();

  const factory PurposeStatus({
    required Decision decision,
    required String policyVersion,
  }) = _PurposeStatus;

  static const undecided = PurposeStatus(
    decision: Decision.undecided,
    policyVersion: "",
  );

  pb.ConsentState toProto() => switch (decision) {
    Decision.undecided => pb.ConsentState.CONSENT_STATE_UNSPECIFIED,
    Decision.granted => pb.ConsentState.CONSENT_STATE_GRANTED,
    Decision.withdrawn => pb.ConsentState.CONSENT_STATE_WITHDRAWN,
  };
}

@freezed
abstract class Consent with _$Consent {
  const Consent._();

  const factory Consent({
    @Default(IMapConst({})) IMap<Purpose, PurposeStatus> purposes,
  }) = _Consent;

  static const none = Consent();

  PurposeStatus statusOf(Purpose purpose) =>
      purposes[purpose] ?? PurposeStatus.undecided;

  bool permits(Purpose purpose) =>
      statusOf(purpose).decision == Decision.granted;

  bool get anyGranted => Purpose.values.any(permits);

  bool get anyDecided =>
      Purpose.values.any((p) => statusOf(p).decision != Decision.undecided);

  Consent granted(Purpose purpose, String policyVersion) => copyWith(
    purposes: purposes.add(
      purpose,
      PurposeStatus(decision: Decision.granted, policyVersion: policyVersion),
    ),
  );

  Consent withdrawn(Purpose purpose) => copyWith(
    purposes: purposes.add(
      purpose,
      PurposeStatus(
        decision: Decision.withdrawn,
        policyVersion: statusOf(purpose).policyVersion,
      ),
    ),
  );

  pb.ConsentSnapshot toProto() => pb.ConsentSnapshot(
    purposes: [
      for (final entry in purposes.entries)
        if (entry.value.decision != Decision.undecided)
          pb.PurposeState(
            purpose: entry.key.toProto(),
            state: entry.value.toProto(),
            policyVersion: entry.value.policyVersion,
          ),
    ],
  );

  factory Consent.fromProto(pb.ConsentSnapshot snapshot) => Consent(
    purposes: IMap.fromEntries([
      for (final state in snapshot.purposes)
        if (purposeFromProto(state.purpose) case final purpose?)
          MapEntry(
            purpose,
            PurposeStatus(
              decision: switch (state.state) {
                pb.ConsentState.CONSENT_STATE_GRANTED => Decision.granted,
                pb.ConsentState.CONSENT_STATE_WITHDRAWN => Decision.withdrawn,
                _ => Decision.undecided,
              },
              policyVersion: state.policyVersion,
            ),
          ),
    ]),
  );
}
