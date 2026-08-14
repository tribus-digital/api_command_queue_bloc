# Changelog

## 0.3.0

- Requires `api_command_queue` 0.3.x, which schedules retry backoff instead of
  sleeping it inside `flush()`.
- Both cubits forward the new `nextDueAt`, so a consumer holding a cubit or an
  orchestrator can tell when to flush again rather than poll for it.

## 0.2.0
 - update api_command_queue version to 0.2.0

## 0.1.0

- Companion adapter package for `api_command_queue` Dart library
- Adds `Cubit` and `HydratedCubit` wrappers for core queues and orchestrators.
- Mirrors wrapped queue and orchestrator state synchronously through the public `state` getter.