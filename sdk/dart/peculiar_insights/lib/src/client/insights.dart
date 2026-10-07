import "dart:async";
import "dart:convert";
import "dart:typed_data";

import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:peculiar_insights/gen/peculiar/insights/v1/common.pb.dart"
    as pb;
import "package:peculiar_insights/gen/peculiar/insights/v1/ingest.pb.dart"
    as pb;
import "package:peculiar_insights/src/client/dispatcher.dart";
import "package:peculiar_insights/src/client/options.dart";
import "package:peculiar_insights/src/client/policy.dart";
import "package:peculiar_insights/src/client/state.dart";
import "package:peculiar_insights/src/consent/buffer.dart";
import "package:peculiar_insights/src/crash/stack_parser.dart";
import "package:peculiar_insights/src/model/consent.dart";
import "package:peculiar_insights/src/model/context.dart";
import "package:peculiar_insights/src/model/crash.dart";
import "package:peculiar_insights/src/model/device_change.dart";
import "package:peculiar_insights/src/model/diagnostic.dart";
import "package:peculiar_insights/src/model/ids.dart";
import "package:peculiar_insights/src/model/item.dart";
import "package:peculiar_insights/src/model/properties.dart";
import "package:peculiar_insights/src/model/value.dart";
import "package:peculiar_insights/src/queue/storage.dart";
import "package:peculiar_insights/src/session/session.dart";
import "package:peculiar_insights/src/transport/transport.dart";
import "package:uuid/uuid.dart";

part "captured_crashes.dart";
part "tracker.dart";

typedef IdMinter = String Function();

String mintUuid() => const Uuid().v4();

final class Insights {
  Insights._({
    required InsightsOptions options,
    required Storage storage,
    required AppContext context,
    required DateTime Function() now,
    required IdMinter newId,
    required Transport transport,
    required ClientState state,
  }) : _options = options,
       _storage = storage,
       _context = context,
       _now = now,
       _newId = newId,
       _state = state {
    _dispatcher = Dispatcher(
      storage: storage,
      transport: transport,
      now: now,
      batchSize: options.batchSize,
      consent: () => _state.consent,
      emit: _emit,
    );
    _timer = Timer.periodic(options.flushInterval, (_) => unawaited(flush()));
  }

  static Future<Insights> start({
    required Uri url,
    required String key,
    required ConsentPolicy consent,
    required AppInfo app,
    required Storage storage,
    PlatformInfo platform = PlatformInfo.unknown,
    InsightsOptions options = const InsightsOptions(),
    Transport? transport,
    DateTime Function() now = DateTime.now,
    IdMinter newId = mintUuid,
  }) async {
    final storedDevice = await storage.readState(StateKeys.deviceId);
    final storedConsent = await storage.readState(StateKeys.consent);
    final storedUser = await storage.readState(StateKeys.userId);
    final persisted = storedConsent == null
        ? Consent.none
        : Consent.fromProto(
            pb.ConsentSnapshot.fromBuffer(base64Decode(storedConsent)),
          );
    final signalled = options.privacyControlSignal && !persisted.anyDecided
        ? Purpose.values.fold(persisted, (c, p) => c.withdrawn(p))
        : persisted;
    final started = now();
    final insights = Insights._(
      options: options,
      storage: storage,
      context: AppContext(
        sdkName: options.sdkName,
        sdkVersion: sdkVersion,
        appVersion: app.version,
        appBuild: app.build,
        platform: platform,
      ),
      now: now,
      newId: newId,
      transport:
          transport ??
          GrpcTransport.endpoint(
            endpoint: url,
            key: key,
            timeout: options.callTimeout,
          ),
      state: ClientState(
        deviceId: DeviceId(storedDevice ?? newId()),
        devicePersisted: storedDevice != null,
        userId: storedUser == null ? null : UserId(storedUser),
        consent: signalled,
        session: Session(id: newId(), lastActivity: started),
        buffer: PendingBuffer(limit: options.bufferLimit),
      ),
    );
    await insights._applyPolicy(consent);
    unawaited(insights.flush());
    return insights;
  }

  final InsightsOptions _options;
  final Storage _storage;
  final AppContext _context;
  final DateTime Function() _now;
  final IdMinter _newId;
  final StreamController<Diagnostic> _diagnostics =
      StreamController.broadcast();
  final StreamController<DeviceChange> _changes = StreamController.broadcast();
  late final Dispatcher _dispatcher;
  late final Timer _timer;
  ClientState _state;

  late final tracker = Tracker._(
    this,
    const _DeviceBinding(),
    const IMapConst({}),
  );

  late final consent = ConsentControls._(this);

  Stream<Diagnostic> get diagnostics => _diagnostics.stream;

  Stream<DeviceChange> get changes => _changes.stream;

  DeviceId get deviceId => _state.deviceId;

  UserId? get userId => _state.userId;

  SessionId get sessionId => SessionId(_state.session.id);

  int get buffered => _state.buffer.length;

  Tracker subject(Subject subject, Consent consent) => Tracker._(
    this,
    _FixedBinding(subject: subject, consent: consent),
    const IMapConst({}),
  );

  Future<void> flush() => _dispatcher.flush();

  Future<void> erase() async {
    final request = pb.RequestErasureRequest(
      id: _newId(),
      time: timestampOf(_now()),
      deviceId: _state.deviceId.value,
      userId: _state.userId?.value,
    );
    await _storage.clearQueue();
    await _storage.append(
      IList([
        QueueRow(
          id: request.id,
          kind: QueueKind.erasure,
          purpose: Purpose.analytics,
          payload: request.writeToBuffer(),
          createdAt: _now().millisecondsSinceEpoch,
        ),
      ]),
    );
    await _storage.deleteState(StateKeys.userId);
    _state = _state.copyWith(
      userId: null,
      deviceId: DeviceId(_newId()),
      devicePersisted: false,
      buffer: PendingBuffer(limit: _options.bufferLimit),
    );
    await _persistDeviceIfAllowed();
    _announce(const DeviceChange.erased());
    await flush();
  }

  Future<void> close() async {
    _timer.cancel();
    _dispatcher.dispose();
    await _diagnostics.close();
    await _changes.close();
    await _storage.close();
  }

  void paused() {
    _state = _state.copyWith(
      session: _state.session.copyWith(lastActivity: _now()),
    );
  }

  void resumed() {
    _touchSession();
  }

  void _announce(DeviceChange change) {
    if (!_changes.isClosed) {
      _changes.add(change);
    }
  }

  void _emit(Diagnostic diagnostic) {
    if (!_diagnostics.isClosed) {
      _diagnostics.add(diagnostic);
    }
  }

  Future<void> _applyPolicy(ConsentPolicy policy) async {
    switch (policy) {
      case AskPolicy():
        return;
      case AssumedPolicy(:final analytics, :final diagnostics):
        for (final (purpose, basis) in [
          (Purpose.analytics, analytics),
          (Purpose.diagnostics, diagnostics),
        ]) {
          if (basis != null &&
              _state.consent.statusOf(purpose).decision == Decision.undecided) {
            await _grant(purpose, basis);
          }
        }
    }
  }

  Subject _deviceSubject() {
    _touchSession();
    return Subject(
      device: _state.deviceId,
      user: _state.userId,
      session: SessionId(_state.session.id),
    );
  }

  void _touchSession() {
    _state = _state.copyWith(
      session: _state.session.touched(
        now: _now(),
        timeout: _options.sessionTimeout,
        newId: _newId,
      ),
    );
  }

  String _scrub(String text) => _options.scrubber?.scrub(text) ?? text;

  IMap<String, Value> _scrubAll(IMap<String, Value> values) =>
      _options.scrubber?.scrubAll(values) ?? values;

  IMap<String, Value> _convert(Properties properties) {
    final converted = convertProperties(properties);
    assert(
      converted.failures.isEmpty,
      "unconvertible property: ${converted.failures.first}",
    );
    converted.failures.forEach(_emit);
    return _scrubAll(converted.values);
  }

  void _log(LogLine line) {
    _state = _state.copyWith(
      logs: appendLog(_state.logs, line, _options.logLimit),
    );
  }

  Future<void> _enqueueDevice(Outgoing item) async {
    switch (_state.consent.statusOf(item.purpose).decision) {
      case Decision.granted:
        await _store(IList([item]), null);
      case Decision.undecided:
        _state = _state.copyWith(buffer: _state.buffer.push(item));
      case Decision.withdrawn:
        _emit(
          const Diagnostic.dropped(
            count: 1,
            reason: "the purpose is withdrawn",
          ),
        );
    }
  }

  Future<void> _enqueueFixed(Outgoing item, Consent consent) async {
    if (consent.permits(item.purpose)) {
      await _store(IList([item]), consent.toProto().writeToBuffer());
    } else {
      _emit(
        const Diagnostic.dropped(
          count: 1,
          reason: "the subject's consent does not permit the purpose",
        ),
      );
    }
  }

  Future<void> _store(IList<Outgoing> items, Uint8List? consent) =>
      _storage.append(
        items
            .map(
              (item) => QueueRow(
                id: item.id,
                kind: QueueKind.publish,
                purpose: item.purpose,
                payload: item.toProto().writeToBuffer(),
                createdAt: _now().millisecondsSinceEpoch,
                consent: consent,
              ),
            )
            .toIList(),
      );

  Future<void> _persistDeviceIfAllowed() async {
    if (_state.consent.anyGranted && !_state.devicePersisted) {
      await _storage.writeState(StateKeys.deviceId, _state.deviceId.value);
      _state = _state.copyWith(devicePersisted: true);
    }
  }

  Future<void> _persistConsent() => _storage.writeState(
    StateKeys.consent,
    base64Encode(_state.consent.toProto().writeToBuffer()),
  );

  Future<void> _recordConsent(Purpose purpose, PurposeStatus status) async {
    final request = pb.RecordConsentRequest(
      id: _newId(),
      time: timestampOf(_now()),
      deviceId: _state.deviceId.value,
      userId: _state.userId?.value,
      purpose: pb.PurposeState(
        purpose: purpose.toProto(),
        state: status.toProto(),
        policyVersion: status.policyVersion,
      ),
    );
    await _storage.append(
      IList([
        QueueRow(
          id: request.id,
          kind: QueueKind.consent,
          purpose: purpose,
          payload: request.writeToBuffer(),
          createdAt: _now().millisecondsSinceEpoch,
        ),
      ]),
    );
  }

  Future<void> _grant(Purpose purpose, String policyVersion) async {
    _state = _state.copyWith(
      consent: _state.consent.granted(purpose, policyVersion),
    );
    await _persistDeviceIfAllowed();
    await _persistConsent();
    if (_state.userId case final userId?) {
      await _storage.writeState(StateKeys.userId, userId.value);
    }
    await _recordConsent(purpose, _state.consent.statusOf(purpose));
    _announce(DeviceChange.consented(_state.consent));
    final held = _state.buffer.of(purpose);
    _state = _state.copyWith(buffer: _state.buffer.drop(purpose));
    await _store(held, null);
    await flush();
  }

  Future<void> _withdraw(Purpose purpose) async {
    final before = _state.consent.statusOf(purpose).decision;
    _state = _state.copyWith(
      consent: _state.consent.withdrawn(purpose),
      buffer: _state.buffer.drop(purpose),
    );
    await _persistConsent();
    if (before == Decision.granted) {
      await _storage.removePurpose(purpose);
      await _recordConsent(purpose, _state.consent.statusOf(purpose));
    }
    if (!_state.consent.anyGranted) {
      await _storage.deleteState(StateKeys.deviceId);
      await _storage.deleteState(StateKeys.userId);
      _state = _state.copyWith(devicePersisted: false);
    }
    _announce(DeviceChange.consented(_state.consent));
    await flush();
  }
}

final class ConsentControls {
  ConsentControls._(this._insights);

  final Insights _insights;

  Consent get status => _insights._state.consent;

  Future<void> grant(Purpose purpose, {required String policyVersion}) =>
      _insights._grant(purpose, policyVersion);

  Future<void> withdraw(Purpose purpose) => _insights._withdraw(purpose);
}
