// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetTaskCollection on Isar {
  IsarCollection<Task> get tasks => this.collection();
}

const TaskSchema = CollectionSchema(
  name: r'Task',
  id: 2998003626758701373,
  properties: {
    r'color': PropertySchema(
      id: 0,
      name: r'color',
      type: IsarType.long,
    ),
    r'completedAt': PropertySchema(
      id: 1,
      name: r'completedAt',
      type: IsarType.dateTime,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'isNotificationEnabled': PropertySchema(
      id: 3,
      name: r'isNotificationEnabled',
      type: IsarType.bool,
    ),
    r'note': PropertySchema(
      id: 4,
      name: r'note',
      type: IsarType.string,
    ),
    r'priority': PropertySchema(
      id: 5,
      name: r'priority',
      type: IsarType.byte,
      enumMap: _TaskpriorityEnumValueMap,
    ),
    r'priorityName': PropertySchema(
      id: 6,
      name: r'priorityName',
      type: IsarType.string,
    ),
    r'recurrence': PropertySchema(
      id: 7,
      name: r'recurrence',
      type: IsarType.byte,
      enumMap: _TaskrecurrenceEnumValueMap,
    ),
    r'recurrenceName': PropertySchema(
      id: 8,
      name: r'recurrenceName',
      type: IsarType.string,
    ),
    r'scheduledAt': PropertySchema(
      id: 9,
      name: r'scheduledAt',
      type: IsarType.dateTime,
    ),
    r'scheduledEnd': PropertySchema(
      id: 10,
      name: r'scheduledEnd',
      type: IsarType.dateTime,
    ),
    r'seriesId': PropertySchema(
      id: 11,
      name: r'seriesId',
      type: IsarType.string,
    ),
    r'status': PropertySchema(
      id: 12,
      name: r'status',
      type: IsarType.byte,
      enumMap: _TaskstatusEnumValueMap,
    ),
    r'tags': PropertySchema(
      id: 13,
      name: r'tags',
      type: IsarType.stringList,
    ),
    r'templateId': PropertySchema(
      id: 14,
      name: r'templateId',
      type: IsarType.long,
    ),
    r'title': PropertySchema(
      id: 15,
      name: r'title',
      type: IsarType.string,
    ),
    r'titleLower': PropertySchema(
      id: 16,
      name: r'titleLower',
      type: IsarType.string,
    )
  },
  estimateSize: _taskEstimateSize,
  serialize: _taskSerialize,
  deserialize: _taskDeserialize,
  deserializeProp: _taskDeserializeProp,
  idName: r'id',
  indexes: {
    r'scheduledAt': IndexSchema(
      id: -1483275037155116518,
      name: r'scheduledAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'scheduledAt',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'scheduledEnd': IndexSchema(
      id: 3012965124172800662,
      name: r'scheduledEnd',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'scheduledEnd',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'color': IndexSchema(
      id: 880366885425937065,
      name: r'color',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'color',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'status': IndexSchema(
      id: -107785170620420283,
      name: r'status',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'status',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'priority': IndexSchema(
      id: -6477851841645083544,
      name: r'priority',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'priority',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'isNotificationEnabled': IndexSchema(
      id: -5909095470642377994,
      name: r'isNotificationEnabled',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'isNotificationEnabled',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'seriesId': IndexSchema(
      id: -6366517829284187702,
      name: r'seriesId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'seriesId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'templateId': IndexSchema(
      id: -5352721467389445085,
      name: r'templateId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'templateId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'titleLower': IndexSchema(
      id: -2652193349673264940,
      name: r'titleLower',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'titleLower',
          type: IndexType.value,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _taskGetId,
  getLinks: _taskGetLinks,
  attach: _taskAttach,
  version: '3.1.0+1',
);

int _taskEstimateSize(
  Task object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.note;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.priorityName.length * 3;
  bytesCount += 3 + object.recurrenceName.length * 3;
  {
    final value = object.seriesId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.tags.length * 3;
  {
    for (var i = 0; i < object.tags.length; i++) {
      final value = object.tags[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.title.length * 3;
  bytesCount += 3 + object.titleLower.length * 3;
  return bytesCount;
}

void _taskSerialize(
  Task object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.color);
  writer.writeDateTime(offsets[1], object.completedAt);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeBool(offsets[3], object.isNotificationEnabled);
  writer.writeString(offsets[4], object.note);
  writer.writeByte(offsets[5], object.priority.index);
  writer.writeString(offsets[6], object.priorityName);
  writer.writeByte(offsets[7], object.recurrence.index);
  writer.writeString(offsets[8], object.recurrenceName);
  writer.writeDateTime(offsets[9], object.scheduledAt);
  writer.writeDateTime(offsets[10], object.scheduledEnd);
  writer.writeString(offsets[11], object.seriesId);
  writer.writeByte(offsets[12], object.status.index);
  writer.writeStringList(offsets[13], object.tags);
  writer.writeLong(offsets[14], object.templateId);
  writer.writeString(offsets[15], object.title);
  writer.writeString(offsets[16], object.titleLower);
}

Task _taskDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Task(
    color: reader.readLongOrNull(offsets[0]),
    completedAt: reader.readDateTimeOrNull(offsets[1]),
    createdAt: reader.readDateTime(offsets[2]),
    id: id,
    isNotificationEnabled: reader.readBoolOrNull(offsets[3]) ?? true,
    note: reader.readStringOrNull(offsets[4]),
    priority: _TaskpriorityValueEnumMap[reader.readByteOrNull(offsets[5])] ??
        TaskPriority.medium,
    recurrence:
        _TaskrecurrenceValueEnumMap[reader.readByteOrNull(offsets[7])] ??
            TaskRecurrence.none,
    scheduledAt: reader.readDateTime(offsets[9]),
    scheduledEnd: reader.readDateTimeOrNull(offsets[10]),
    seriesId: reader.readStringOrNull(offsets[11]),
    status: _TaskstatusValueEnumMap[reader.readByteOrNull(offsets[12])] ??
        TaskStatus.active,
    tags: reader.readStringList(offsets[13]) ?? const [],
    templateId: reader.readLongOrNull(offsets[14]),
    title: reader.readString(offsets[15]),
  );
  return object;
}

P _taskDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset)) as P;
    case 1:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readBoolOrNull(offset) ?? true) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (_TaskpriorityValueEnumMap[reader.readByteOrNull(offset)] ??
          TaskPriority.medium) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (_TaskrecurrenceValueEnumMap[reader.readByteOrNull(offset)] ??
          TaskRecurrence.none) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readDateTime(offset)) as P;
    case 10:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (_TaskstatusValueEnumMap[reader.readByteOrNull(offset)] ??
          TaskStatus.active) as P;
    case 13:
      return (reader.readStringList(offset) ?? const []) as P;
    case 14:
      return (reader.readLongOrNull(offset)) as P;
    case 15:
      return (reader.readString(offset)) as P;
    case 16:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _TaskpriorityEnumValueMap = {
  'low': 0,
  'medium': 1,
  'high': 2,
};
const _TaskpriorityValueEnumMap = {
  0: TaskPriority.low,
  1: TaskPriority.medium,
  2: TaskPriority.high,
};
const _TaskrecurrenceEnumValueMap = {
  'none': 0,
  'daily': 1,
  'weekly': 2,
  'monthly': 3,
};
const _TaskrecurrenceValueEnumMap = {
  0: TaskRecurrence.none,
  1: TaskRecurrence.daily,
  2: TaskRecurrence.weekly,
  3: TaskRecurrence.monthly,
};
const _TaskstatusEnumValueMap = {
  'active': 0,
  'completed': 1,
  'cancelled': 2,
};
const _TaskstatusValueEnumMap = {
  0: TaskStatus.active,
  1: TaskStatus.completed,
  2: TaskStatus.cancelled,
};

Id _taskGetId(Task object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _taskGetLinks(Task object) {
  return [];
}

void _taskAttach(IsarCollection<dynamic> col, Id id, Task object) {
  object.id = id;
}

extension TaskQueryWhereSort on QueryBuilder<Task, Task, QWhere> {
  QueryBuilder<Task, Task, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<Task, Task, QAfterWhere> anyScheduledAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'scheduledAt'),
      );
    });
  }

  QueryBuilder<Task, Task, QAfterWhere> anyScheduledEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'scheduledEnd'),
      );
    });
  }

  QueryBuilder<Task, Task, QAfterWhere> anyColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'color'),
      );
    });
  }

  QueryBuilder<Task, Task, QAfterWhere> anyStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'status'),
      );
    });
  }

  QueryBuilder<Task, Task, QAfterWhere> anyPriority() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'priority'),
      );
    });
  }

  QueryBuilder<Task, Task, QAfterWhere> anyIsNotificationEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'isNotificationEnabled'),
      );
    });
  }

  QueryBuilder<Task, Task, QAfterWhere> anyTemplateId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'templateId'),
      );
    });
  }

  QueryBuilder<Task, Task, QAfterWhere> anyTitleLower() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'titleLower'),
      );
    });
  }
}

extension TaskQueryWhere on QueryBuilder<Task, Task, QWhereClause> {
  QueryBuilder<Task, Task, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> scheduledAtEqualTo(
      DateTime scheduledAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'scheduledAt',
        value: [scheduledAt],
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> scheduledAtNotEqualTo(
      DateTime scheduledAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'scheduledAt',
              lower: [],
              upper: [scheduledAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'scheduledAt',
              lower: [scheduledAt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'scheduledAt',
              lower: [scheduledAt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'scheduledAt',
              lower: [],
              upper: [scheduledAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> scheduledAtGreaterThan(
    DateTime scheduledAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'scheduledAt',
        lower: [scheduledAt],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> scheduledAtLessThan(
    DateTime scheduledAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'scheduledAt',
        lower: [],
        upper: [scheduledAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> scheduledAtBetween(
    DateTime lowerScheduledAt,
    DateTime upperScheduledAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'scheduledAt',
        lower: [lowerScheduledAt],
        includeLower: includeLower,
        upper: [upperScheduledAt],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> scheduledEndIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'scheduledEnd',
        value: [null],
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> scheduledEndIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'scheduledEnd',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> scheduledEndEqualTo(
      DateTime? scheduledEnd) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'scheduledEnd',
        value: [scheduledEnd],
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> scheduledEndNotEqualTo(
      DateTime? scheduledEnd) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'scheduledEnd',
              lower: [],
              upper: [scheduledEnd],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'scheduledEnd',
              lower: [scheduledEnd],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'scheduledEnd',
              lower: [scheduledEnd],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'scheduledEnd',
              lower: [],
              upper: [scheduledEnd],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> scheduledEndGreaterThan(
    DateTime? scheduledEnd, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'scheduledEnd',
        lower: [scheduledEnd],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> scheduledEndLessThan(
    DateTime? scheduledEnd, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'scheduledEnd',
        lower: [],
        upper: [scheduledEnd],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> scheduledEndBetween(
    DateTime? lowerScheduledEnd,
    DateTime? upperScheduledEnd, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'scheduledEnd',
        lower: [lowerScheduledEnd],
        includeLower: includeLower,
        upper: [upperScheduledEnd],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> colorIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'color',
        value: [null],
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> colorIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'color',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> colorEqualTo(int? color) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'color',
        value: [color],
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> colorNotEqualTo(int? color) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'color',
              lower: [],
              upper: [color],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'color',
              lower: [color],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'color',
              lower: [color],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'color',
              lower: [],
              upper: [color],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> colorGreaterThan(
    int? color, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'color',
        lower: [color],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> colorLessThan(
    int? color, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'color',
        lower: [],
        upper: [color],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> colorBetween(
    int? lowerColor,
    int? upperColor, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'color',
        lower: [lowerColor],
        includeLower: includeLower,
        upper: [upperColor],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> statusEqualTo(TaskStatus status) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'status',
        value: [status],
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> statusNotEqualTo(
      TaskStatus status) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'status',
              lower: [],
              upper: [status],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'status',
              lower: [status],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'status',
              lower: [status],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'status',
              lower: [],
              upper: [status],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> statusGreaterThan(
    TaskStatus status, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'status',
        lower: [status],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> statusLessThan(
    TaskStatus status, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'status',
        lower: [],
        upper: [status],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> statusBetween(
    TaskStatus lowerStatus,
    TaskStatus upperStatus, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'status',
        lower: [lowerStatus],
        includeLower: includeLower,
        upper: [upperStatus],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> priorityEqualTo(
      TaskPriority priority) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'priority',
        value: [priority],
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> priorityNotEqualTo(
      TaskPriority priority) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'priority',
              lower: [],
              upper: [priority],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'priority',
              lower: [priority],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'priority',
              lower: [priority],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'priority',
              lower: [],
              upper: [priority],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> priorityGreaterThan(
    TaskPriority priority, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'priority',
        lower: [priority],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> priorityLessThan(
    TaskPriority priority, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'priority',
        lower: [],
        upper: [priority],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> priorityBetween(
    TaskPriority lowerPriority,
    TaskPriority upperPriority, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'priority',
        lower: [lowerPriority],
        includeLower: includeLower,
        upper: [upperPriority],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> isNotificationEnabledEqualTo(
      bool isNotificationEnabled) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'isNotificationEnabled',
        value: [isNotificationEnabled],
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> isNotificationEnabledNotEqualTo(
      bool isNotificationEnabled) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isNotificationEnabled',
              lower: [],
              upper: [isNotificationEnabled],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isNotificationEnabled',
              lower: [isNotificationEnabled],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isNotificationEnabled',
              lower: [isNotificationEnabled],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isNotificationEnabled',
              lower: [],
              upper: [isNotificationEnabled],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> seriesIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'seriesId',
        value: [null],
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> seriesIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'seriesId',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> seriesIdEqualTo(
      String? seriesId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'seriesId',
        value: [seriesId],
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> seriesIdNotEqualTo(
      String? seriesId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'seriesId',
              lower: [],
              upper: [seriesId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'seriesId',
              lower: [seriesId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'seriesId',
              lower: [seriesId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'seriesId',
              lower: [],
              upper: [seriesId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> templateIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'templateId',
        value: [null],
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> templateIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'templateId',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> templateIdEqualTo(
      int? templateId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'templateId',
        value: [templateId],
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> templateIdNotEqualTo(
      int? templateId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'templateId',
              lower: [],
              upper: [templateId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'templateId',
              lower: [templateId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'templateId',
              lower: [templateId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'templateId',
              lower: [],
              upper: [templateId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> templateIdGreaterThan(
    int? templateId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'templateId',
        lower: [templateId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> templateIdLessThan(
    int? templateId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'templateId',
        lower: [],
        upper: [templateId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> templateIdBetween(
    int? lowerTemplateId,
    int? upperTemplateId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'templateId',
        lower: [lowerTemplateId],
        includeLower: includeLower,
        upper: [upperTemplateId],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> titleLowerEqualTo(
      String titleLower) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'titleLower',
        value: [titleLower],
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> titleLowerNotEqualTo(
      String titleLower) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'titleLower',
              lower: [],
              upper: [titleLower],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'titleLower',
              lower: [titleLower],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'titleLower',
              lower: [titleLower],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'titleLower',
              lower: [],
              upper: [titleLower],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> titleLowerGreaterThan(
    String titleLower, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'titleLower',
        lower: [titleLower],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> titleLowerLessThan(
    String titleLower, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'titleLower',
        lower: [],
        upper: [titleLower],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> titleLowerBetween(
    String lowerTitleLower,
    String upperTitleLower, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'titleLower',
        lower: [lowerTitleLower],
        includeLower: includeLower,
        upper: [upperTitleLower],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> titleLowerStartsWith(
      String TitleLowerPrefix) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'titleLower',
        lower: [TitleLowerPrefix],
        upper: ['$TitleLowerPrefix\u{FFFFF}'],
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> titleLowerIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'titleLower',
        value: [''],
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterWhereClause> titleLowerIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.lessThan(
              indexName: r'titleLower',
              upper: [''],
            ))
            .addWhereClause(IndexWhereClause.greaterThan(
              indexName: r'titleLower',
              lower: [''],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.greaterThan(
              indexName: r'titleLower',
              lower: [''],
            ))
            .addWhereClause(IndexWhereClause.lessThan(
              indexName: r'titleLower',
              upper: [''],
            ));
      }
    });
  }
}

extension TaskQueryFilter on QueryBuilder<Task, Task, QFilterCondition> {
  QueryBuilder<Task, Task, QAfterFilterCondition> colorIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'color',
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> colorIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'color',
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> colorEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'color',
        value: value,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> colorGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'color',
        value: value,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> colorLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'color',
        value: value,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> colorBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'color',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> completedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'completedAt',
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> completedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'completedAt',
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> completedAtEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'completedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> completedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'completedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> completedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'completedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> completedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'completedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> createdAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> isNotificationEnabledEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isNotificationEnabled',
        value: value,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> noteIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'note',
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> noteIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'note',
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> noteEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> noteGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> noteLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> noteBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'note',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> noteStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> noteEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> noteContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> noteMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'note',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> noteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'note',
        value: '',
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> noteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'note',
        value: '',
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> priorityEqualTo(
      TaskPriority value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'priority',
        value: value,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> priorityGreaterThan(
    TaskPriority value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'priority',
        value: value,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> priorityLessThan(
    TaskPriority value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'priority',
        value: value,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> priorityBetween(
    TaskPriority lower,
    TaskPriority upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'priority',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> priorityNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'priorityName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> priorityNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'priorityName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> priorityNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'priorityName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> priorityNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'priorityName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> priorityNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'priorityName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> priorityNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'priorityName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> priorityNameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'priorityName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> priorityNameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'priorityName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> priorityNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'priorityName',
        value: '',
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> priorityNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'priorityName',
        value: '',
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> recurrenceEqualTo(
      TaskRecurrence value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'recurrence',
        value: value,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> recurrenceGreaterThan(
    TaskRecurrence value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'recurrence',
        value: value,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> recurrenceLessThan(
    TaskRecurrence value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'recurrence',
        value: value,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> recurrenceBetween(
    TaskRecurrence lower,
    TaskRecurrence upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'recurrence',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> recurrenceNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'recurrenceName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> recurrenceNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'recurrenceName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> recurrenceNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'recurrenceName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> recurrenceNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'recurrenceName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> recurrenceNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'recurrenceName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> recurrenceNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'recurrenceName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> recurrenceNameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'recurrenceName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> recurrenceNameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'recurrenceName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> recurrenceNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'recurrenceName',
        value: '',
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> recurrenceNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'recurrenceName',
        value: '',
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> scheduledAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scheduledAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> scheduledAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'scheduledAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> scheduledAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'scheduledAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> scheduledAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'scheduledAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> scheduledEndIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'scheduledEnd',
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> scheduledEndIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'scheduledEnd',
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> scheduledEndEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scheduledEnd',
        value: value,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> scheduledEndGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'scheduledEnd',
        value: value,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> scheduledEndLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'scheduledEnd',
        value: value,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> scheduledEndBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'scheduledEnd',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> seriesIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'seriesId',
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> seriesIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'seriesId',
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> seriesIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'seriesId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> seriesIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'seriesId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> seriesIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'seriesId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> seriesIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'seriesId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> seriesIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'seriesId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> seriesIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'seriesId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> seriesIdContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'seriesId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> seriesIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'seriesId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> seriesIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'seriesId',
        value: '',
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> seriesIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'seriesId',
        value: '',
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> statusEqualTo(
      TaskStatus value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: value,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> statusGreaterThan(
    TaskStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'status',
        value: value,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> statusLessThan(
    TaskStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'status',
        value: value,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> statusBetween(
    TaskStatus lower,
    TaskStatus upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'status',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> tagsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> tagsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> tagsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> tagsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tags',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> tagsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> tagsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> tagsElementContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> tagsElementMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'tags',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> tagsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tags',
        value: '',
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> tagsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'tags',
        value: '',
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> tagsLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> tagsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> tagsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> tagsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> tagsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> tagsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> templateIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'templateId',
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> templateIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'templateId',
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> templateIdEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'templateId',
        value: value,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> templateIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'templateId',
        value: value,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> templateIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'templateId',
        value: value,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> templateIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'templateId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> titleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'title',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> titleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> titleContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> titleMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> titleLowerEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'titleLower',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> titleLowerGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'titleLower',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> titleLowerLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'titleLower',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> titleLowerBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'titleLower',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> titleLowerStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'titleLower',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> titleLowerEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'titleLower',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> titleLowerContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'titleLower',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> titleLowerMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'titleLower',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> titleLowerIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'titleLower',
        value: '',
      ));
    });
  }

  QueryBuilder<Task, Task, QAfterFilterCondition> titleLowerIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'titleLower',
        value: '',
      ));
    });
  }
}

extension TaskQueryObject on QueryBuilder<Task, Task, QFilterCondition> {}

extension TaskQueryLinks on QueryBuilder<Task, Task, QFilterCondition> {}

extension TaskQuerySortBy on QueryBuilder<Task, Task, QSortBy> {
  QueryBuilder<Task, Task, QAfterSortBy> sortByColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'color', Sort.asc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> sortByColorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'color', Sort.desc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> sortByCompletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.asc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> sortByCompletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.desc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> sortByIsNotificationEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isNotificationEnabled', Sort.asc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> sortByIsNotificationEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isNotificationEnabled', Sort.desc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> sortByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> sortByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> sortByPriority() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priority', Sort.asc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> sortByPriorityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priority', Sort.desc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> sortByPriorityName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priorityName', Sort.asc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> sortByPriorityNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priorityName', Sort.desc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> sortByRecurrence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recurrence', Sort.asc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> sortByRecurrenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recurrence', Sort.desc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> sortByRecurrenceName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recurrenceName', Sort.asc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> sortByRecurrenceNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recurrenceName', Sort.desc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> sortByScheduledAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledAt', Sort.asc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> sortByScheduledAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledAt', Sort.desc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> sortByScheduledEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledEnd', Sort.asc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> sortByScheduledEndDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledEnd', Sort.desc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> sortBySeriesId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seriesId', Sort.asc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> sortBySeriesIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seriesId', Sort.desc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> sortByTemplateId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'templateId', Sort.asc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> sortByTemplateIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'templateId', Sort.desc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> sortByTitleLower() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'titleLower', Sort.asc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> sortByTitleLowerDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'titleLower', Sort.desc);
    });
  }
}

extension TaskQuerySortThenBy on QueryBuilder<Task, Task, QSortThenBy> {
  QueryBuilder<Task, Task, QAfterSortBy> thenByColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'color', Sort.asc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> thenByColorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'color', Sort.desc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> thenByCompletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.asc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> thenByCompletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.desc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> thenByIsNotificationEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isNotificationEnabled', Sort.asc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> thenByIsNotificationEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isNotificationEnabled', Sort.desc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> thenByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> thenByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> thenByPriority() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priority', Sort.asc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> thenByPriorityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priority', Sort.desc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> thenByPriorityName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priorityName', Sort.asc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> thenByPriorityNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priorityName', Sort.desc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> thenByRecurrence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recurrence', Sort.asc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> thenByRecurrenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recurrence', Sort.desc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> thenByRecurrenceName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recurrenceName', Sort.asc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> thenByRecurrenceNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recurrenceName', Sort.desc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> thenByScheduledAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledAt', Sort.asc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> thenByScheduledAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledAt', Sort.desc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> thenByScheduledEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledEnd', Sort.asc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> thenByScheduledEndDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledEnd', Sort.desc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> thenBySeriesId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seriesId', Sort.asc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> thenBySeriesIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seriesId', Sort.desc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> thenByTemplateId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'templateId', Sort.asc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> thenByTemplateIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'templateId', Sort.desc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> thenByTitleLower() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'titleLower', Sort.asc);
    });
  }

  QueryBuilder<Task, Task, QAfterSortBy> thenByTitleLowerDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'titleLower', Sort.desc);
    });
  }
}

extension TaskQueryWhereDistinct on QueryBuilder<Task, Task, QDistinct> {
  QueryBuilder<Task, Task, QDistinct> distinctByColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'color');
    });
  }

  QueryBuilder<Task, Task, QDistinct> distinctByCompletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'completedAt');
    });
  }

  QueryBuilder<Task, Task, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<Task, Task, QDistinct> distinctByIsNotificationEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isNotificationEnabled');
    });
  }

  QueryBuilder<Task, Task, QDistinct> distinctByNote(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'note', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Task, Task, QDistinct> distinctByPriority() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'priority');
    });
  }

  QueryBuilder<Task, Task, QDistinct> distinctByPriorityName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'priorityName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Task, Task, QDistinct> distinctByRecurrence() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'recurrence');
    });
  }

  QueryBuilder<Task, Task, QDistinct> distinctByRecurrenceName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'recurrenceName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Task, Task, QDistinct> distinctByScheduledAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'scheduledAt');
    });
  }

  QueryBuilder<Task, Task, QDistinct> distinctByScheduledEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'scheduledEnd');
    });
  }

  QueryBuilder<Task, Task, QDistinct> distinctBySeriesId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'seriesId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Task, Task, QDistinct> distinctByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status');
    });
  }

  QueryBuilder<Task, Task, QDistinct> distinctByTags() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tags');
    });
  }

  QueryBuilder<Task, Task, QDistinct> distinctByTemplateId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'templateId');
    });
  }

  QueryBuilder<Task, Task, QDistinct> distinctByTitle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Task, Task, QDistinct> distinctByTitleLower(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'titleLower', caseSensitive: caseSensitive);
    });
  }
}

extension TaskQueryProperty on QueryBuilder<Task, Task, QQueryProperty> {
  QueryBuilder<Task, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Task, int?, QQueryOperations> colorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'color');
    });
  }

  QueryBuilder<Task, DateTime?, QQueryOperations> completedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'completedAt');
    });
  }

  QueryBuilder<Task, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<Task, bool, QQueryOperations> isNotificationEnabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isNotificationEnabled');
    });
  }

  QueryBuilder<Task, String?, QQueryOperations> noteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'note');
    });
  }

  QueryBuilder<Task, TaskPriority, QQueryOperations> priorityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'priority');
    });
  }

  QueryBuilder<Task, String, QQueryOperations> priorityNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'priorityName');
    });
  }

  QueryBuilder<Task, TaskRecurrence, QQueryOperations> recurrenceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'recurrence');
    });
  }

  QueryBuilder<Task, String, QQueryOperations> recurrenceNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'recurrenceName');
    });
  }

  QueryBuilder<Task, DateTime, QQueryOperations> scheduledAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'scheduledAt');
    });
  }

  QueryBuilder<Task, DateTime?, QQueryOperations> scheduledEndProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'scheduledEnd');
    });
  }

  QueryBuilder<Task, String?, QQueryOperations> seriesIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'seriesId');
    });
  }

  QueryBuilder<Task, TaskStatus, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<Task, List<String>, QQueryOperations> tagsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tags');
    });
  }

  QueryBuilder<Task, int?, QQueryOperations> templateIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'templateId');
    });
  }

  QueryBuilder<Task, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<Task, String, QQueryOperations> titleLowerProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'titleLower');
    });
  }
}
