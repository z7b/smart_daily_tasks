// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_profile_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetWorkProfileCollection on Isar {
  IsarCollection<WorkProfile> get workProfiles => this.collection();
}

const WorkProfileSchema = CollectionSchema(
  name: r'WorkProfile',
  id: 1367248828187346451,
  properties: {
    r'companyName': PropertySchema(
      id: 0,
      name: r'companyName',
      type: IsarType.string,
    ),
    r'customSchedulesJson': PropertySchema(
      id: 1,
      name: r'customSchedulesJson',
      type: IsarType.string,
    ),
    r'employmentStatus': PropertySchema(
      id: 2,
      name: r'employmentStatus',
      type: IsarType.byte,
      enumMap: _WorkProfileemploymentStatusEnumValueMap,
    ),
    r'endMinutes': PropertySchema(
      id: 3,
      name: r'endMinutes',
      type: IsarType.long,
    ),
    r'jobPosition': PropertySchema(
      id: 4,
      name: r'jobPosition',
      type: IsarType.string,
    ),
    r'jobTitle': PropertySchema(
      id: 5,
      name: r'jobTitle',
      type: IsarType.string,
    ),
    r'monthlySalary': PropertySchema(
      id: 6,
      name: r'monthlySalary',
      type: IsarType.double,
    ),
    r'officialWorkHours': PropertySchema(
      id: 7,
      name: r'officialWorkHours',
      type: IsarType.double,
    ),
    r'remindersEnabled': PropertySchema(
      id: 8,
      name: r'remindersEnabled',
      type: IsarType.bool,
    ),
    r'salaryDay': PropertySchema(
      id: 9,
      name: r'salaryDay',
      type: IsarType.long,
    ),
    r'startMinutes': PropertySchema(
      id: 10,
      name: r'startMinutes',
      type: IsarType.long,
    ),
    r'workingDays': PropertySchema(
      id: 11,
      name: r'workingDays',
      type: IsarType.longList,
    )
  },
  estimateSize: _workProfileEstimateSize,
  serialize: _workProfileSerialize,
  deserialize: _workProfileDeserialize,
  deserializeProp: _workProfileDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _workProfileGetId,
  getLinks: _workProfileGetLinks,
  attach: _workProfileAttach,
  version: '3.1.0+1',
);

int _workProfileEstimateSize(
  WorkProfile object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.companyName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.customSchedulesJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.jobPosition;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.jobTitle;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.workingDays.length * 8;
  return bytesCount;
}

void _workProfileSerialize(
  WorkProfile object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.companyName);
  writer.writeString(offsets[1], object.customSchedulesJson);
  writer.writeByte(offsets[2], object.employmentStatus.index);
  writer.writeLong(offsets[3], object.endMinutes);
  writer.writeString(offsets[4], object.jobPosition);
  writer.writeString(offsets[5], object.jobTitle);
  writer.writeDouble(offsets[6], object.monthlySalary);
  writer.writeDouble(offsets[7], object.officialWorkHours);
  writer.writeBool(offsets[8], object.remindersEnabled);
  writer.writeLong(offsets[9], object.salaryDay);
  writer.writeLong(offsets[10], object.startMinutes);
  writer.writeLongList(offsets[11], object.workingDays);
}

WorkProfile _workProfileDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = WorkProfile(
    companyName: reader.readStringOrNull(offsets[0]),
    customSchedulesJson: reader.readStringOrNull(offsets[1]),
    employmentStatus: _WorkProfileemploymentStatusValueEnumMap[
            reader.readByteOrNull(offsets[2])] ??
        EmploymentStatus.notConfigured,
    endMinutes: reader.readLongOrNull(offsets[3]) ?? 1020,
    id: id,
    jobPosition: reader.readStringOrNull(offsets[4]),
    jobTitle: reader.readStringOrNull(offsets[5]),
    monthlySalary: reader.readDoubleOrNull(offsets[6]),
    officialWorkHours: reader.readDoubleOrNull(offsets[7]),
    remindersEnabled: reader.readBoolOrNull(offsets[8]) ?? true,
    salaryDay: reader.readLongOrNull(offsets[9]) ?? 25,
    startMinutes: reader.readLongOrNull(offsets[10]) ?? 540,
    workingDays: reader.readLongList(offsets[11]) ?? const [1, 2, 3, 4, 5],
  );
  return object;
}

P _workProfileDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (_WorkProfileemploymentStatusValueEnumMap[
              reader.readByteOrNull(offset)] ??
          EmploymentStatus.notConfigured) as P;
    case 3:
      return (reader.readLongOrNull(offset) ?? 1020) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readDoubleOrNull(offset)) as P;
    case 7:
      return (reader.readDoubleOrNull(offset)) as P;
    case 8:
      return (reader.readBoolOrNull(offset) ?? true) as P;
    case 9:
      return (reader.readLongOrNull(offset) ?? 25) as P;
    case 10:
      return (reader.readLongOrNull(offset) ?? 540) as P;
    case 11:
      return (reader.readLongList(offset) ?? const [1, 2, 3, 4, 5]) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _WorkProfileemploymentStatusEnumValueMap = {
  'notConfigured': 0,
  'employed': 1,
  'unemployed': 2,
};
const _WorkProfileemploymentStatusValueEnumMap = {
  0: EmploymentStatus.notConfigured,
  1: EmploymentStatus.employed,
  2: EmploymentStatus.unemployed,
};

Id _workProfileGetId(WorkProfile object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _workProfileGetLinks(WorkProfile object) {
  return [];
}

void _workProfileAttach(
    IsarCollection<dynamic> col, Id id, WorkProfile object) {
  object.id = id;
}

extension WorkProfileQueryWhereSort
    on QueryBuilder<WorkProfile, WorkProfile, QWhere> {
  QueryBuilder<WorkProfile, WorkProfile, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension WorkProfileQueryWhere
    on QueryBuilder<WorkProfile, WorkProfile, QWhereClause> {
  QueryBuilder<WorkProfile, WorkProfile, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<WorkProfile, WorkProfile, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterWhereClause> idBetween(
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
}

extension WorkProfileQueryFilter
    on QueryBuilder<WorkProfile, WorkProfile, QFilterCondition> {
  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      companyNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'companyName',
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      companyNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'companyName',
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      companyNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'companyName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      companyNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'companyName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      companyNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'companyName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      companyNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'companyName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      companyNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'companyName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      companyNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'companyName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      companyNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'companyName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      companyNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'companyName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      companyNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'companyName',
        value: '',
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      companyNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'companyName',
        value: '',
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      customSchedulesJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'customSchedulesJson',
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      customSchedulesJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'customSchedulesJson',
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      customSchedulesJsonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'customSchedulesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      customSchedulesJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'customSchedulesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      customSchedulesJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'customSchedulesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      customSchedulesJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'customSchedulesJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      customSchedulesJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'customSchedulesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      customSchedulesJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'customSchedulesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      customSchedulesJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'customSchedulesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      customSchedulesJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'customSchedulesJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      customSchedulesJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'customSchedulesJson',
        value: '',
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      customSchedulesJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'customSchedulesJson',
        value: '',
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      employmentStatusEqualTo(EmploymentStatus value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'employmentStatus',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      employmentStatusGreaterThan(
    EmploymentStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'employmentStatus',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      employmentStatusLessThan(
    EmploymentStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'employmentStatus',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      employmentStatusBetween(
    EmploymentStatus lower,
    EmploymentStatus upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'employmentStatus',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      endMinutesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      endMinutesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'endMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      endMinutesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'endMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      endMinutesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'endMinutes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition> idBetween(
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

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      jobPositionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'jobPosition',
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      jobPositionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'jobPosition',
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      jobPositionEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'jobPosition',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      jobPositionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'jobPosition',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      jobPositionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'jobPosition',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      jobPositionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'jobPosition',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      jobPositionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'jobPosition',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      jobPositionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'jobPosition',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      jobPositionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'jobPosition',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      jobPositionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'jobPosition',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      jobPositionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'jobPosition',
        value: '',
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      jobPositionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'jobPosition',
        value: '',
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      jobTitleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'jobTitle',
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      jobTitleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'jobTitle',
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition> jobTitleEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'jobTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      jobTitleGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'jobTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      jobTitleLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'jobTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition> jobTitleBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'jobTitle',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      jobTitleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'jobTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      jobTitleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'jobTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      jobTitleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'jobTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition> jobTitleMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'jobTitle',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      jobTitleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'jobTitle',
        value: '',
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      jobTitleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'jobTitle',
        value: '',
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      monthlySalaryIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'monthlySalary',
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      monthlySalaryIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'monthlySalary',
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      monthlySalaryEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'monthlySalary',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      monthlySalaryGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'monthlySalary',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      monthlySalaryLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'monthlySalary',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      monthlySalaryBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'monthlySalary',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      officialWorkHoursIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'officialWorkHours',
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      officialWorkHoursIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'officialWorkHours',
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      officialWorkHoursEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'officialWorkHours',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      officialWorkHoursGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'officialWorkHours',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      officialWorkHoursLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'officialWorkHours',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      officialWorkHoursBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'officialWorkHours',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      remindersEnabledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remindersEnabled',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      salaryDayEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'salaryDay',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      salaryDayGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'salaryDay',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      salaryDayLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'salaryDay',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      salaryDayBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'salaryDay',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      startMinutesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      startMinutesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      startMinutesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      startMinutesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startMinutes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      workingDaysElementEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'workingDays',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      workingDaysElementGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'workingDays',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      workingDaysElementLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'workingDays',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      workingDaysElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'workingDays',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      workingDaysLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'workingDays',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      workingDaysIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'workingDays',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      workingDaysIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'workingDays',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      workingDaysLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'workingDays',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      workingDaysLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'workingDays',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterFilterCondition>
      workingDaysLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'workingDays',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension WorkProfileQueryObject
    on QueryBuilder<WorkProfile, WorkProfile, QFilterCondition> {}

extension WorkProfileQueryLinks
    on QueryBuilder<WorkProfile, WorkProfile, QFilterCondition> {}

extension WorkProfileQuerySortBy
    on QueryBuilder<WorkProfile, WorkProfile, QSortBy> {
  QueryBuilder<WorkProfile, WorkProfile, QAfterSortBy> sortByCompanyName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'companyName', Sort.asc);
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterSortBy> sortByCompanyNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'companyName', Sort.desc);
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterSortBy>
      sortByCustomSchedulesJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customSchedulesJson', Sort.asc);
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterSortBy>
      sortByCustomSchedulesJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customSchedulesJson', Sort.desc);
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterSortBy>
      sortByEmploymentStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'employmentStatus', Sort.asc);
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterSortBy>
      sortByEmploymentStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'employmentStatus', Sort.desc);
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterSortBy> sortByEndMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endMinutes', Sort.asc);
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterSortBy> sortByEndMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endMinutes', Sort.desc);
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterSortBy> sortByJobPosition() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jobPosition', Sort.asc);
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterSortBy> sortByJobPositionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jobPosition', Sort.desc);
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterSortBy> sortByJobTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jobTitle', Sort.asc);
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterSortBy> sortByJobTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jobTitle', Sort.desc);
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterSortBy> sortByMonthlySalary() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'monthlySalary', Sort.asc);
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterSortBy>
      sortByMonthlySalaryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'monthlySalary', Sort.desc);
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterSortBy>
      sortByOfficialWorkHours() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'officialWorkHours', Sort.asc);
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterSortBy>
      sortByOfficialWorkHoursDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'officialWorkHours', Sort.desc);
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterSortBy>
      sortByRemindersEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remindersEnabled', Sort.asc);
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterSortBy>
      sortByRemindersEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remindersEnabled', Sort.desc);
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterSortBy> sortBySalaryDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'salaryDay', Sort.asc);
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterSortBy> sortBySalaryDayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'salaryDay', Sort.desc);
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterSortBy> sortByStartMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startMinutes', Sort.asc);
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterSortBy>
      sortByStartMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startMinutes', Sort.desc);
    });
  }
}

extension WorkProfileQuerySortThenBy
    on QueryBuilder<WorkProfile, WorkProfile, QSortThenBy> {
  QueryBuilder<WorkProfile, WorkProfile, QAfterSortBy> thenByCompanyName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'companyName', Sort.asc);
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterSortBy> thenByCompanyNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'companyName', Sort.desc);
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterSortBy>
      thenByCustomSchedulesJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customSchedulesJson', Sort.asc);
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterSortBy>
      thenByCustomSchedulesJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customSchedulesJson', Sort.desc);
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterSortBy>
      thenByEmploymentStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'employmentStatus', Sort.asc);
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterSortBy>
      thenByEmploymentStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'employmentStatus', Sort.desc);
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterSortBy> thenByEndMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endMinutes', Sort.asc);
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterSortBy> thenByEndMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endMinutes', Sort.desc);
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterSortBy> thenByJobPosition() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jobPosition', Sort.asc);
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterSortBy> thenByJobPositionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jobPosition', Sort.desc);
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterSortBy> thenByJobTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jobTitle', Sort.asc);
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterSortBy> thenByJobTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jobTitle', Sort.desc);
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterSortBy> thenByMonthlySalary() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'monthlySalary', Sort.asc);
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterSortBy>
      thenByMonthlySalaryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'monthlySalary', Sort.desc);
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterSortBy>
      thenByOfficialWorkHours() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'officialWorkHours', Sort.asc);
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterSortBy>
      thenByOfficialWorkHoursDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'officialWorkHours', Sort.desc);
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterSortBy>
      thenByRemindersEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remindersEnabled', Sort.asc);
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterSortBy>
      thenByRemindersEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remindersEnabled', Sort.desc);
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterSortBy> thenBySalaryDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'salaryDay', Sort.asc);
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterSortBy> thenBySalaryDayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'salaryDay', Sort.desc);
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterSortBy> thenByStartMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startMinutes', Sort.asc);
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QAfterSortBy>
      thenByStartMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startMinutes', Sort.desc);
    });
  }
}

extension WorkProfileQueryWhereDistinct
    on QueryBuilder<WorkProfile, WorkProfile, QDistinct> {
  QueryBuilder<WorkProfile, WorkProfile, QDistinct> distinctByCompanyName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'companyName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QDistinct>
      distinctByCustomSchedulesJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'customSchedulesJson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QDistinct>
      distinctByEmploymentStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'employmentStatus');
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QDistinct> distinctByEndMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endMinutes');
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QDistinct> distinctByJobPosition(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'jobPosition', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QDistinct> distinctByJobTitle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'jobTitle', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QDistinct> distinctByMonthlySalary() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'monthlySalary');
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QDistinct>
      distinctByOfficialWorkHours() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'officialWorkHours');
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QDistinct>
      distinctByRemindersEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remindersEnabled');
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QDistinct> distinctBySalaryDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'salaryDay');
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QDistinct> distinctByStartMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startMinutes');
    });
  }

  QueryBuilder<WorkProfile, WorkProfile, QDistinct> distinctByWorkingDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'workingDays');
    });
  }
}

extension WorkProfileQueryProperty
    on QueryBuilder<WorkProfile, WorkProfile, QQueryProperty> {
  QueryBuilder<WorkProfile, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<WorkProfile, String?, QQueryOperations> companyNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'companyName');
    });
  }

  QueryBuilder<WorkProfile, String?, QQueryOperations>
      customSchedulesJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'customSchedulesJson');
    });
  }

  QueryBuilder<WorkProfile, EmploymentStatus, QQueryOperations>
      employmentStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'employmentStatus');
    });
  }

  QueryBuilder<WorkProfile, int, QQueryOperations> endMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endMinutes');
    });
  }

  QueryBuilder<WorkProfile, String?, QQueryOperations> jobPositionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'jobPosition');
    });
  }

  QueryBuilder<WorkProfile, String?, QQueryOperations> jobTitleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'jobTitle');
    });
  }

  QueryBuilder<WorkProfile, double?, QQueryOperations> monthlySalaryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'monthlySalary');
    });
  }

  QueryBuilder<WorkProfile, double?, QQueryOperations>
      officialWorkHoursProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'officialWorkHours');
    });
  }

  QueryBuilder<WorkProfile, bool, QQueryOperations> remindersEnabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remindersEnabled');
    });
  }

  QueryBuilder<WorkProfile, int, QQueryOperations> salaryDayProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'salaryDay');
    });
  }

  QueryBuilder<WorkProfile, int, QQueryOperations> startMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startMinutes');
    });
  }

  QueryBuilder<WorkProfile, List<int>, QQueryOperations> workingDaysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'workingDays');
    });
  }
}
