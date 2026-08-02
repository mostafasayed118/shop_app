import 'package:e_commerce/core/utils/write_queue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WriteQueue', () {
    test('serializes tasks so a burst lands in order', () async {
      final queue = WriteQueue();
      final order = <String>[];

      // Enqueued without awaiting: the second task must still wait for the
      // first to finish, even though the first is deliberately slow.
      final first = queue.enqueue(() async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        order.add('first');
      });
      final second = queue.enqueue(() async {
        order.add('second');
      });

      await first;
      await second;
      expect(order, ['first', 'second']);
    });

    test('a failing task does not block later writes', () async {
      final queue = WriteQueue();
      final order = <String>[];

      final first = queue.enqueue(() async {
        throw StateError('boom');
      });
      final second = queue.enqueue(() async {
        order.add('ran');
      });

      // The failing task's error is contained by the queue.
      await first;
      await second;
      expect(order, ['ran']);
    });
  });
}
