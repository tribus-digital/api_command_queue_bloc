import 'package:api_command_queue/api_command_queue.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

class InMemoryStorage implements Storage {
  final _backing = <String, dynamic>{};

  @override
  Future<void> clear() async => _backing.clear();

  @override
  Future<void> close() async => _backing.clear();

  @override
  Future<void> delete(String key) async => _backing.remove(key);

  @override
  dynamic read(String key) => _backing[key];

  @override
  Future<void> write(String key, dynamic value) async {
    _backing[key] = value;
  }
}

class DummyData {
  const DummyData(this.value);

  final int value;

  Map<String, dynamic> toJson() => {'value': value};

  static DummyData fromJson(Object? json) {
    final map = (json as Map).cast<String, dynamic>();
    return DummyData(map['value'] as int);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DummyData && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

class DummyCommand extends ApiCommand<DummyData, ApiCommandRequest<DummyData>,
    DummyData, DummyCommand> {
  const DummyCommand._({
    required super.uuid,
    required super.request,
    required super.strategy,
    required super.status,
    required super.attemptCount,
    required super.lastUpdated,
    super.firstFailureAt,
    super.apiResponse,
  });

  factory DummyCommand.create(String id, int value) {
    return DummyCommand._(
      uuid: id,
      request: ApiCommandRequest(
        ApiCommandRequestMethod.post,
        DummyData(value),
      ),
      strategy: CommandReplaceStrategy.multiple,
      status: ApiCommandStatus.idle,
      attemptCount: 0,
      firstFailureAt: null,
      lastUpdated: DateTime.now(),
    );
  }

  @override
  Future<ApiCommandResponse<DummyData>?> execute() async {
    return ApiCommandResponse(request.data, false, status: 200);
  }

  @override
  DummyCommand copyWith({
    ApiCommandRequest<DummyData>? request,
    CommandReplaceStrategy? strategy,
    ApiCommandStatus? status,
    DateTime? lastUpdated,
    int? attemptCount,
    DateTime? firstFailureAt,
    ApiCommandResponse<DummyData?>? apiResponse,
  }) {
    return DummyCommand._(
      uuid: uuid,
      request: request ?? this.request,
      strategy: strategy ?? this.strategy,
      status: status ?? this.status,
      attemptCount: attemptCount ?? this.attemptCount,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      firstFailureAt: firstFailureAt ?? this.firstFailureAt,
      apiResponse: apiResponse ?? this.apiResponse,
    );
  }

  @override
  DummyData mergePayload(DummyData update) => update;

  @override
  Object? requestDataToJson(DummyData requestData) => requestData.toJson();

  @override
  Object? responseDataToJson(DummyData? responseData) => responseData?.toJson();

  static DummyCommand fromJson(Map<String, dynamic> json) {
    return DummyCommand._(
      uuid: json['id'] as String,
      request: ApiCommandRequest.fromJson(
        (json['request'] as Map).cast<String, dynamic>(),
        DummyData.fromJson,
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
              DummyData.fromJson,
            ),
    );
  }
}

final class DummyQueue extends ApiCommandQueue<DummyData,
    ApiCommandRequest<DummyData>, DummyData, DummyCommand> {
  DummyQueue() : super(commandFromJson: DummyCommand.fromJson);
}
