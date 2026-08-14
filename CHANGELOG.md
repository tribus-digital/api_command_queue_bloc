# Changelog

## 0.4.0

- Requires `api_command_queue` 0.4.x, which adds
  `ApiCommandOrchestrator.autoFlushWhenDue` so retries progress without
  waiting for the consumer to trigger the next flush.

## 0.3.0

- Requires `api_command_queue` 0.3.x, which schedules retry backoff instead of
  sleeping it inside `flush()`.
- Both cubits forward the new `nextDueAt`, so a consumer holding a cubit or an
  orchestrator can tell when to flush again rather than poll for it.
- Added `HydratedApiCommandQueueCubit.dropUndecodableCommands`, off by default.

  `SyncState.fromJson` decodes the queue in a single pass, so one undecodable
  command throws and takes every other queued command with it: `hydrated_bloc`
  catches the error, falls back to an empty queue and - on its default
  `HydrationErrorBehavior.overwrite` - writes that empty queue back over the
  stored one. Every write the device had not yet sent is lost.

  With the flag on, each command is decoded on its own first and only the ones
  that fail are left out, each reported through `apiCommandQueueLogger`.
  Existing behaviour is unchanged unless it is switched on.

## 0.2.0
 - update api_command_queue version to 0.2.0

## 0.1.0

- Companion adapter package for `api_command_queue` Dart library
- Adds `Cubit` and `HydratedCubit` wrappers for core queues and orchestrators.
- Mirrors wrapped queue and orchestrator state synchronously through the public `state` getter.