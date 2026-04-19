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
    return queue.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(
    SyncState<Payload, Request, Result, Command> state,
  ) {
    return queue.toJson(state);
  }

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
