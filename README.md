# api_command_queue_bloc

`api_command_queue_bloc` provides `Cubit` and `HydratedCubit` adapters for the pure Dart [`api_command_queue`](https://pub.dev/packages/api_command_queue) core package.

It is intended for applications that want to:

- mirror a core queue or orchestrator as a bloc state stream
- persist queue state with `hydrated_bloc`
- keep domain queue logic in the core package while using bloc-based app wiring

## Which Package?

- Use `api_command_queue` when you want framework-agnostic queueing primitives.
- Use `api_command_queue_bloc` when your app already uses `bloc` / `hydrated_bloc` and you want queue state exposed as cubits.

## Install

```yaml
dependencies:
  api_command_queue: ^0.1.0
  api_command_queue_bloc: ^0.1.0
```

## Example

```dart
import 'package:api_command_queue/api_command_queue.dart';
import 'package:api_command_queue_bloc/api_command_queue_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

HydratedBloc.storage = MyStorage();

final queue = ExampleQueue();
final hydrated = HydratedApiCommandQueueCubit(
  queue: queue,
  storagePrefix: 'ExampleQueue',
  storageId: 'primary',
);

await hydrated.flush();
await hydrated.close();
```

See [`example/main.dart`](example/main.dart) for a runnable example.

## Hydration Identity

`HydratedApiCommandQueueCubit` follows `hydrated_bloc` storage-token semantics:

- `storagePrefix` is the persistence namespace
- `storageId` is the per-instance discriminator
- the final key is `storagePrefix + storageId`

For existing apps migrating from a previously hydrated queue class, keep `storagePrefix` aligned with the old queue runtime type or previous storage namespace so persisted queue state continues to restore correctly.

## Typical Setup

The adapter package does not replace the core queue logic. A typical arrangement is:

1. Define commands and queues in `api_command_queue`.
2. Wrap long-lived queues with `HydratedApiCommandQueueCubit` when you want persistence.
3. Wrap the core orchestrator with `ApiCommandOrchestratorCubit` when the rest of the app expects bloc state.

The core queue remains the source of truth for queue behavior. The cubit wrappers mirror state and lifecycle.
