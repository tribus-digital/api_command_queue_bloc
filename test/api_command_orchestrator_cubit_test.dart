import 'package:api_command_queue/api_command_queue.dart';
import 'package:api_command_queue_bloc/api_command_queue_bloc.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  test('ApiCommandOrchestratorCubit mirrors wrapped orchestrator state',
      () async {
    final queue = DummyQueue();
    final orchestrator = ApiCommandOrchestrator(
      commandQueues: {DummyCommand: queue},
    );
    final cubit = ApiCommandOrchestratorCubit(orchestrator: orchestrator);

    orchestrator.enqueue(DummyCommand.create('one', 1));
    await orchestrator.flushAll();

    expect(cubit.state, equals(QueueFlushStatus.idle));

    await cubit.close();
    expect(orchestrator.isClosed, isTrue);
  });
}
