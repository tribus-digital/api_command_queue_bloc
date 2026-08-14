import 'dart:async';

import 'package:api_command_queue/api_command_queue.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

/// Persists a core [ApiCommandQueue] using `hydrated_bloc`.
class HydratedApiCommandQueueCubit<
        Payload,
        Request extends ApiCommandRequest<Payload>,
        Result,
        Command extends ApiCommand<Payload, Request, Result, Command>>
    extends HydratedCubit<SyncState<Payload, Request, Result, Command>>
    implements ApiCommandQueueHandle<Payload, Request, Result, Command> {
  HydratedApiCommandQueueCubit({
    required this.queue,
    String? storagePrefix,
    String? storageId,
    this.closeWrappedQueue = true,
    this.dropUndecodableCommands = false,
  })  : _storagePrefix = storagePrefix ?? queue.runtimeType.toString(),
        _storageId = storageId ?? '',
        super(queue.state) {
    queue.restoreState(super.state);
    _subscription = queue.stream.listen(emit);
  }

  /// The wrapped core queue.
  final ApiCommandQueue<Payload, Request, Result, Command> queue;

  final String _storagePrefix;
  final String _storageId;

  /// Whether closing the cubit should also close the wrapped queue.
  final bool closeWrappedQueue;

  /// Whether a command that cannot be restored is dropped instead of failing
  /// the whole restore.
  ///
  /// `SyncState.fromJson` decodes the queue in a single pass, so one
  /// undecodable command throws and takes every other queued command with it:
  /// `hydrated_bloc` catches the error, falls back to an empty queue, and - on
  /// its default `HydrationErrorBehavior.overwrite` - writes that empty queue
  /// back over the stored one. Every write the device had not yet sent is lost,
  /// with nothing to show for it but an `onError` call.
  ///
  /// Off by default, because dropping a command is itself data loss and a
  /// consumer should choose it knowingly. Switching it on trades one unreadable
  /// command for all of them. Each one dropped is reported through
  /// [apiCommandQueueLogger].
  final bool dropUndecodableCommands;

  StreamSubscription<SyncState<Payload, Request, Result, Command>>?
      _subscription;

  @override
  SyncState<Payload, Request, Result, Command> get state => queue.state;

  @override
  String get storagePrefix => _storagePrefix;

  @override
  String get id => _storageId;

  @override
  SyncState<Payload, Request, Result, Command> fromJson(
    Map<String, dynamic> json,
  ) {
    return queue.fromJson(
      dropUndecodableCommands ? _withoutUndecodableCommands(json) : json,
    );
  }

  static const _commandBuckets = ['pending', 'failed'];

  /// Rebuilds [json] with any command that fails to decode left out of it.
  ///
  /// Each command is decoded on its own first, since the state decoder gives no
  /// way to skip one.
  Map<String, dynamic> _withoutUndecodableCommands(Map<String, dynamic> json) {
    final flushStatus = json['flushStatus'];
    final result = <String, dynamic>{'flushStatus': flushStatus};

    for (final bucket in _commandBuckets) {
      final commands =
          (json[bucket] as Map?)?.cast<String, dynamic>() ?? const {};
      final decodable = <String, dynamic>{};

      commands.forEach((uuid, command) {
        try {
          queue.fromJson({
            'pending': {uuid: command},
            'failed': const <String, dynamic>{},
            'flushStatus': flushStatus,
          });
          decodable[uuid] = command;
        } catch (error, stackTrace) {
          apiCommandQueueLogger.error(
            '[$runtimeType] dropping $bucket command $uuid - it could not be '
            'restored',
            error: error,
            stackTrace: stackTrace,
          );
        }
      });

      result[bucket] = decodable;
    }

    return result;
  }

  @override
  Map<String, dynamic> toJson(
    SyncState<Payload, Request, Result, Command> state,
  ) {
    return queue.toJson(state);
  }

  @override
  DateTime? get nextDueAt => queue.nextDueAt;

  @override
  int get inFlightCount => queue.inFlightCount;

  @override
  bool get isPaused => queue.isPaused;

  @override
  bool get isFlushing => queue.isFlushing;

  @override
  Stream<ApiCommandResult<Command, Result>> get results => queue.results;

  @override
  void addCommand(
    covariant Command command, {
    bool processNow = false,
    Duration? debounce,
  }) {
    queue.addCommand(command, processNow: processNow, debounce: debounce);
  }

  @override
  Future<void> flush() => queue.flush();

  @override
  void pause() => queue.pause();

  @override
  void resume({bool flushNow = false}) => queue.resume(flushNow: flushNow);

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    _subscription = null;
    if (closeWrappedQueue) {
      await queue.close();
    }
    await super.close();
  }
}
