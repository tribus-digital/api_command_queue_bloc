import 'package:api_command_queue/api_command_queue.dart';
import 'package:api_command_queue_bloc/api_command_queue_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  setUp(() {
    HydratedBloc.storage = InMemoryStorage();
  });

  test('HydratedApiCommandQueueCubit persists later queue updates', () async {
    final queue = DummyQueue();
    final cubit = HydratedApiCommandQueueCubit(
      queue: queue,
      storagePrefix: 'dummy_queue',
    );

    queue.addCommand(DummyCommand.create('one', 1));
    await Future<void>.delayed(Duration.zero);

    final raw = HydratedBloc.storage.read(cubit.storageToken);
    expect(raw, isA<Map<String, dynamic>>());
    expect(
      ((raw as Map<String, dynamic>)['pending'] as Map<String, dynamic>)
          .containsKey('one'),
      isTrue,
    );

    await cubit.close();
  });

  test('HydratedApiCommandQueueCubit restores persisted state into queue',
      () async {
    final storage = HydratedBloc.storage as InMemoryStorage;
    final seedQueue = DummyQueue();
    const storagePrefix = 'dummy_restore';
    const storageId = '_instance';
    final seededState = seedQueue.toJson(
      SyncState<DummyData, ApiCommandRequest<DummyData>, DummyData,
          DummyCommand>(
        pending: {'one': DummyCommand.create('one', 1)},
        failed: const {},
      ),
    );
    await storage.write('$storagePrefix$storageId', seededState);

    final queue = DummyQueue();
    final cubit = HydratedApiCommandQueueCubit(
      queue: queue,
      storagePrefix: storagePrefix,
      storageId: storageId,
    );

    expect(queue.state.pending.containsKey('one'), isTrue);
    expect(cubit.state.pending.containsKey('one'), isTrue);

    await cubit.close();
  });
}
