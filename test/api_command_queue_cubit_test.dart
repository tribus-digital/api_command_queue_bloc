import 'package:api_command_queue_bloc/api_command_queue_bloc.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  test('ApiCommandQueueCubit mirrors wrapped queue state', () async {
    final queue = DummyQueue();
    final cubit = ApiCommandQueueCubit(queue: queue);

    queue.addCommand(DummyCommand.create('one', 1));
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.pending.containsKey('one'), isTrue);

    await cubit.close();
    expect(queue.isClosed, isTrue);
  });
}
