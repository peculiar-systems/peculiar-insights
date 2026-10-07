part of "insights.dart";

extension CapturedCrashes on Insights {
  Future<void> recordCaptured(CapturedCrash crash) => _enqueueDevice(
    Outgoing.crash(
      id: crash.id,
      time: crash.time,
      subject: _deviceSubject(),
      context: _context.copyWith(
        appVersion: crash.app.version,
        appBuild: crash.app.build,
      ),
      exceptionType: crash.exceptionType,
      message: _scrub(crash.message),
      frames: crash.frames,
      rawStackTrace: "",
      fatal: true,
      thread: crash.thread,
      customKeys: const IMapConst({}),
      logs: const IListConst([]),
    ),
  );
}
