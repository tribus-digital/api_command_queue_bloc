import 'dart:async';

import 'package:api_command_queue/api_command_queue.dart';
import 'package:bloc/bloc.dart';

/// Mirrors a core [ApiCommandQueueHandle] as a Cubit state stream.
class ApiCommandQueueCubit<Payload, Request extends ApiCommandRequest<Payload>,
        Result, Command extends ApiCommand<Payload, Request, Result, Command>>
    extends Cubit<SyncState<Payload, Request, Result, Command>>
    implements ApiCommandQueueHandle<Payload, Request, Result, Command> {
  ApiCommandQueueCubit({
    required this.queue,
    this.closeWrappedQueue = true,
  }) : super(queue.state) {
    _subscription = queue.stream.listen(emit);
  }

  /// The wrapped core queue.
  final ApiCommandQueueHandle<Payload, Request, Result, Command> queue;

  /// Whether closing the cubit should also close the wrapped queue.
  final bool closeWrappedQueue;

  StreamSubscription<SyncState<Payload, Request, Result, Command>>?
      _subscription;

  @override
  SyncState<Payload, Request, Result, Command> get state => queue.state;

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
