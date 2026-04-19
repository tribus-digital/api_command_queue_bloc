import 'dart:async';

import 'package:api_command_queue/api_command_queue.dart';
import 'package:api_command_queue_bloc/api_command_queue_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

Future<void> main() async {
  HydratedBloc.storage = _MemoryStorage();

  final queue = _ExampleQueue();
  final hydrated = HydratedApiCommandQueueCubit(
    queue: queue,
    storagePrefix: '_ExampleQueue',
    storageId: 'primary',
  );

  final orchestrator = ApiCommandOrchestrator(
    commandQueues: {_ExampleCommand: queue},
  );
  final orchestratorCubit = ApiCommandOrchestratorCubit(
    orchestrator: orchestrator,
  );

  orchestrator.enqueue(_ExampleCommand.create('Ship adapter docs'));
  final result = await hydrated.results.first;
  print('Completed ${result.command.uuid} success=${result.success}');

  await orchestratorCubit.close();
  await hydrated.close();
}

final class _MemoryStorage implements Storage {
  final Map<String, dynamic> _values = <String, dynamic>{};

  @override
  dynamic read(String key) => _values[key];

  @override
  Future<void> write(String key, dynamic value) async {
    _values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }

  @override
  Future<void> clear() async => _values.clear();

  @override
  Future<void> close() async => _values.clear();
}

final class _ExamplePayload {
  const _ExamplePayload(this.title);

  final String title;

  Map<String, dynamic> toJson() => {'title': title};

  static _ExamplePayload fromJson(Object? json) {
    final map = (json as Map).cast<String, dynamic>();
    return _ExamplePayload(map['title'] as String);
  }
}

final class _ExampleCommand extends ApiCommand<_ExamplePayload,
    ApiCommandRequest<_ExamplePayload>, _ExamplePayload, _ExampleCommand> {
  const _ExampleCommand._({
    required super.uuid,
    required super.request,
    required super.strategy,
    required super.status,
    required super.attemptCount,
    required super.firstFailureAt,
    required super.lastUpdated,
    super.apiResponse,
  });

  factory _ExampleCommand.create(String title) {
    return _ExampleCommand._(
      uuid: ApiCommand.generateId(),
      request: ApiCommandRequest(
        ApiCommandRequestMethod.post,
        _ExamplePayload(title),
      ),
      strategy: CommandReplaceStrategy.multiple,
      status: ApiCommandStatus.idle,
      attemptCount: 0,
      firstFailureAt: null,
      lastUpdated: DateTime.now(),
    );
  }

  @override
  Future<ApiCommandResponse<_ExamplePayload>?> execute() async {
    return ApiCommandResponse(request.data, false, status: 201);
  }

  @override
  _ExamplePayload? offlineResult() => request.data;

  @override
  _ExampleCommand copyWith({
    ApiCommandRequest<_ExamplePayload>? request,
    CommandReplaceStrategy? strategy,
    ApiCommandStatus? status,
    DateTime? lastUpdated,
    int? attemptCount,
    DateTime? firstFailureAt,
    ApiCommandResponse<_ExamplePayload?>? apiResponse,
  }) {
    return _ExampleCommand._(
      uuid: uuid,
      request: request ?? this.request,
      strategy: strategy ?? this.strategy,
      status: status ?? this.status,
      attemptCount: attemptCount ?? this.attemptCount,
      firstFailureAt: firstFailureAt ?? this.firstFailureAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      apiResponse: apiResponse ?? this.apiResponse,
    );
  }

  @override
  _ExamplePayload mergePayload(_ExamplePayload update) => update;

  @override
  Object? requestDataToJson(_ExamplePayload requestData) =>
      requestData.toJson();

  @override
  Object? responseDataToJson(_ExamplePayload? responseData) =>
      responseData?.toJson();

  static _ExampleCommand fromJson(Map<String, dynamic> json) {
    return _ExampleCommand._(
      uuid: json['id'] as String,
      request: ApiCommandRequest.fromJson(
        (json['request'] as Map).cast<String, dynamic>(),
        _ExamplePayload.fromJson,
      ),
      strategy: CommandReplaceStrategy.values.firstWhere(
        (value) => value.name == json['strategy'] as String,
      ),
      status: ApiCommandStatus.values.firstWhere(
        (value) => value.name == json['status'] as String,
      ),
      attemptCount: json['attemptCount'] as int,
      firstFailureAt: json['firstFailureAt'] == null
          ? null
          : DateTime.parse(json['firstFailureAt'] as String),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      apiResponse: json['apiResponse'] == null
          ? null
          : ApiCommandResponse.fromJson(
              (json['apiResponse'] as Map).cast<String, dynamic>(),
              _ExamplePayload.fromJson,
            ),
    );
  }
}

final class _ExampleQueue extends ApiCommandQueue<_ExamplePayload,
    ApiCommandRequest<_ExamplePayload>, _ExamplePayload, _ExampleCommand> {
  _ExampleQueue() : super(commandFromJson: _ExampleCommand.fromJson);
}
