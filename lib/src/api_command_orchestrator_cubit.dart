import 'dart:async';

import 'package:api_command_queue/api_command_queue.dart';
import 'package:bloc/bloc.dart';

/// Mirrors a core [ApiCommandOrchestrator] as a Cubit state stream.
class ApiCommandOrchestratorCubit extends Cubit<QueueFlushStatus> {
  ApiCommandOrchestratorCubit({
    required this.orchestrator,
    this.closeWrappedOrchestrator = true,
  }) : super(orchestrator.state) {
    _subscription = orchestrator.stream.listen(emit);
  }

  /// The wrapped core orchestrator.
  final ApiCommandOrchestrator orchestrator;

  /// Whether closing the cubit should also close the wrapped orchestrator.
  final bool closeWrappedOrchestrator;

  StreamSubscription<QueueFlushStatus>? _subscription;

  @override
  QueueFlushStatus get state => orchestrator.state;

  bool get processingEnabled => orchestrator.processingEnabled;

  Map<Type, AnyApiCommandQueueHandle> get commandQueues =>
      orchestrator.commandQueues;

  Result? enqueue<
      Payload,
      Result,
      Command extends ApiCommand<Payload, ApiCommandRequest<Payload>, Result,
          Command>>(
    Command command, {
    Duration? debounce,
  }) {
    return orchestrator.enqueue(command, debounce: debounce);
  }

  Future<void> flushAll() => orchestrator.flushAll();

  void pauseAll() => orchestrator.pauseAll();

  void resumeAll({bool flushNow = false}) =>
      orchestrator.resumeAll(flushNow: flushNow);

  void setProcessingEnabled(bool enabled) =>
      orchestrator.setProcessingEnabled(enabled);

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    _subscription = null;
    if (closeWrappedOrchestrator) {
      await orchestrator.close();
    }
    await super.close();
  }
}
