import 'package:api_command_queue/api_command_queue.dart';
import 'package:api_command_queue_bloc/api_command_queue_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

/// Persisted state holding two restorable commands and one that cannot be
/// decoded at all.
Map<String, dynamic> _storedState(DummyQueue queue) {
  final good = queue.toJson(
    SyncState<DummyData, ApiCommandRequest<DummyData>, DummyData, DummyCommand>(
      pending: {
        'one': DummyCommand.create('one', 1),
        'two': DummyCommand.create('two', 2),
      },
      failed: const {},
    ),
  );

  (good['pending'] as Map<String, dynamic>)['corrupt'] = <String, dynamic>{
    'id': 'corrupt',
    'nothing': 'usable',
  };

  return good;
}

/// `SyncState.fromJson` decodes the queue in one pass, so an undecodable
/// command throws and takes the rest with it - `hydrated_bloc` then falls back
/// to an empty queue and writes that back over the stored one.
void main() {
  late InMemoryStorage storage;

  setUp(() {
    storage = InMemoryStorage();
    HydratedBloc.storage = storage;
  });

  test('by default one undecodable command empties the queue', () async {
    final queue = DummyQueue();
    await storage.write('drop_off', _storedState(DummyQueue()));

    final cubit = HydratedApiCommandQueueCubit(
      queue: queue,
      storagePrefix: 'drop_off',
    );

    expect(
      queue.state.pending,
      isEmpty,
      reason: 'existing consumers must not have their behaviour changed under them',
    );

    await cubit.close();
  });

  test('dropUndecodableCommands keeps the commands that can be restored', () async {
    final queue = DummyQueue();
    await storage.write('drop_on', _storedState(DummyQueue()));

    final cubit = HydratedApiCommandQueueCubit(
      queue: queue,
      storagePrefix: 'drop_on',
      dropUndecodableCommands: true,
    );

    expect(queue.state.pending.keys.toSet(), {'one', 'two'});
    expect(queue.state.pending.containsKey('corrupt'), isFalse);

    await cubit.close();
  });

  test('a queue with nothing wrong with it restores in full either way', () async {
    for (final drop in [false, true]) {
      final seed = DummyQueue().toJson(
        SyncState<DummyData, ApiCommandRequest<DummyData>, DummyData,
            DummyCommand>(
          pending: {'one': DummyCommand.create('one', 1)},
          failed: const {},
        ),
      );
      await storage.write('intact_$drop', seed);

      final queue = DummyQueue();
      final cubit = HydratedApiCommandQueueCubit(
        queue: queue,
        storagePrefix: 'intact_$drop',
        dropUndecodableCommands: drop,
      );

      expect(queue.state.pending.keys.toSet(), {'one'});

      await cubit.close();
    }
  });

  test('failed commands are pruned too, not just pending', () async {
    final seed = DummyQueue().toJson(
      SyncState<DummyData, ApiCommandRequest<DummyData>, DummyData,
          DummyCommand>(
        pending: {'one': DummyCommand.create('one', 1)},
        failed: {'two': DummyCommand.create('two', 2)},
      ),
    );
    (seed['failed'] as Map<String, dynamic>)['corrupt'] = <String, dynamic>{
      'id': 'corrupt',
    };

    await storage.write('drop_failed', seed);

    final queue = DummyQueue();
    final cubit = HydratedApiCommandQueueCubit(
      queue: queue,
      storagePrefix: 'drop_failed',
      dropUndecodableCommands: true,
    );

    expect(queue.state.pending.keys.toSet(), {'one'});
    expect(queue.state.failed.keys.toSet(), {'two'});

    await cubit.close();
  });
}
