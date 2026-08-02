/// Serializes fire-and-forget writes (e.g. persistence saves) so a fast burst
/// can never land on disk out of order, and a failing write never blocks the
/// ones queued after it.
///
/// Usage:
/// ```dart
/// final writes = WriteQueue();
/// writes.enqueue(() async {
///   try {
///     await repository.save(snapshot);
///   } catch (error) {
///     log(error);
///   }
/// });
/// ```
class WriteQueue {
  Future<void> _tail = Future.value();

  /// Schedules [task] to run after every previously queued task.
  ///
  /// Errors thrown by [task] are contained so the queue stays usable — callers
  /// usually catch and log inside the task themselves.
  Future<void> enqueue(Future<void> Function() task) {
    final result = _tail.then((_) async {
      try {
        await task();
      } catch (_) {
        // A failed task must not poison the chain for later writes.
      }
    });
    _tail = result;
    return result;
  }
}
