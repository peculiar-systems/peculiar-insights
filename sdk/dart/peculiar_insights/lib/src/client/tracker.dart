part of "insights.dart";

sealed class _Binding {
  const _Binding();
}

final class _DeviceBinding extends _Binding {
  const _DeviceBinding();
}

final class _FixedBinding extends _Binding {
  const _FixedBinding({required this.subject, required this.consent});

  final Subject subject;
  final Consent consent;
}

final class Tracker {
  const Tracker._(this._insights, this._binding, this.properties);

  final Insights _insights;
  final _Binding _binding;
  final IMap<String, Value> properties;

  People get people => People._(this);

  Tracker with_(Properties properties) => Tracker._(
    _insights,
    _binding,
    this.properties.addAll(_insights._convert(properties)),
  );

  Future<void> track(String name, [Properties properties = const {}]) =>
      _enqueue(
        Outgoing.event(
          id: _insights._newId(),
          time: _insights._now(),
          subject: _subject(),
          context: _insights._context,
          name: name,
          properties: this.properties.addAll(_insights._convert(properties)),
        ),
      );

  Future<void> identify(UserId userId) async {
    final device = switch (_binding) {
      _DeviceBinding() => _insights._state.deviceId,
      _FixedBinding(:final subject) => subject.device,
    };
    if (_binding is _DeviceBinding) {
      _insights._state = _insights._state.copyWith(userId: userId);
      if (_insights._state.consent.permits(Purpose.analytics)) {
        await _insights._storage.writeState(StateKeys.userId, userId.value);
      }
    }
    await _enqueue(
      Outgoing.identify(
        id: _insights._newId(),
        time: _insights._now(),
        deviceId: device,
        userId: userId,
      ),
    );
  }

  Future<void> reset() async {
    if (_binding is _FixedBinding) {
      _insights._emit(
        const Diagnostic.dropped(
          count: 1,
          reason: "reset applies to the device tracker only",
        ),
      );
      return;
    }
    _insights._state = _insights._state.copyWith(
      deviceId: DeviceId(_insights._newId()),
      devicePersisted: false,
      userId: null,
      session: Session(id: _insights._newId(), lastActivity: _insights._now()),
    );
    await _insights._storage.deleteState(StateKeys.userId);
    await _insights._persistDeviceIfAllowed();
  }

  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
    String thread = "main",
  }) async {
    final raw = stackTrace.toString();
    await _enqueue(
      Outgoing.crash(
        id: _insights._newId(),
        time: _insights._now(),
        subject: _subject(),
        context: _insights._context,
        exceptionType: error.runtimeType.toString(),
        message: _insights._scrub(error.toString()),
        frames: parseStackTrace(
          raw,
          inAppPackages: _insights._options.inAppPackages,
        ),
        rawStackTrace: _insights._scrub(raw),
        fatal: fatal,
        thread: thread,
        customKeys: properties,
        logs: _insights._state.logs,
      ),
    );
    if (fatal) {
      await _insights.flush();
    }
  }

  Future<T> attempt<T>(FutureOr<T> Function() action) async {
    try {
      return await action();
    } on Object catch (error, stackTrace) {
      await recordError(error, stackTrace);
      rethrow;
    }
  }

  void log(String message, {LogLevel level = LogLevel.info}) {
    _insights._log(
      LogLine(
        time: _insights._now(),
        level: level,
        message: _insights._scrub(message),
      ),
    );
  }

  Span span(String name) => Span._(this, name, _insights._now());

  Subject _subject() => switch (_binding) {
    _DeviceBinding() => _insights._deviceSubject(),
    _FixedBinding(:final subject) => subject,
  };

  Future<void> _enqueue(Outgoing item) => switch (_binding) {
    _DeviceBinding() => _insights._enqueueDevice(item),
    _FixedBinding(:final consent) => _insights._enqueueFixed(item, consent),
  };
}

final class Span {
  Span._(this._tracker, this.name, this.started);

  final Tracker _tracker;
  final String name;
  final DateTime started;
  var _ended = false;

  Future<void> end([Properties properties = const {}]) {
    if (_ended) {
      _tracker._insights._emit(
        Diagnostic.dropped(count: 1, reason: "the span $name already ended"),
      );
      return Future.value();
    }
    _ended = true;
    final elapsed = _tracker._insights._now().difference(started);
    return _tracker.track(name, {
      ...properties,
      "duration_ms": elapsed.inMilliseconds,
    });
  }
}

final class People {
  People._(this._tracker);

  final Tracker _tracker;

  Future<void> set(Properties properties) => _apply(
    _tracker._insights
        ._convert(properties)
        .entries
        .map((e) => ProfileOperation.set(e.key, e.value))
        .toIList(),
  );

  Future<void> setOnce(Properties properties) => _apply(
    _tracker._insights
        ._convert(properties)
        .entries
        .map((e) => ProfileOperation.setOnce(e.key, e.value))
        .toIList(),
  );

  Future<void> unset(Iterable<String> keys) =>
      _apply(keys.map(ProfileOperation.unset).toIList());

  Future<void> _apply(IList<ProfileOperation> operations) async {
    final subject = _tracker._subject();
    final userId = subject.user;
    if (userId == null) {
      _tracker._insights._emit(
        const Diagnostic.dropped(
          count: 1,
          reason: "a profile update needs an identified user",
        ),
      );
      return;
    }
    await _tracker._enqueue(
      Outgoing.profile(
        id: _tracker._insights._newId(),
        time: _tracker._insights._now(),
        deviceId: subject.device,
        userId: userId,
        operations: operations,
      ),
    );
  }
}
