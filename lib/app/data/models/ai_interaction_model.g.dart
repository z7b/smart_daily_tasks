// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_interaction_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetAiInteractionCollection on Isar {
  IsarCollection<AiInteraction> get aiInteractions => this.collection();
}

const AiInteractionSchema = CollectionSchema(
  name: r'AiInteraction',
  id: 1131533283248101234,
  properties: {
    r'confidence': PropertySchema(
      id: 0,
      name: r'confidence',
      type: IsarType.double,
    ),
    r'correctedIntent': PropertySchema(
      id: 1,
      name: r'correctedIntent',
      type: IsarType.string,
    ),
    r'detectedIntent': PropertySchema(
      id: 2,
      name: r'detectedIntent',
      type: IsarType.string,
    ),
    r'extractedEntitiesJson': PropertySchema(
      id: 3,
      name: r'extractedEntitiesJson',
      type: IsarType.string,
    ),
    r'timestamp': PropertySchema(
      id: 4,
      name: r'timestamp',
      type: IsarType.dateTime,
    ),
    r'userInput': PropertySchema(
      id: 5,
      name: r'userInput',
      type: IsarType.string,
    )
  },
  estimateSize: _aiInteractionEstimateSize,
  serialize: _aiInteractionSerialize,
  deserialize: _aiInteractionDeserialize,
  deserializeProp: _aiInteractionDeserializeProp,
  idName: r'id',
  indexes: {
    r'userInput': IndexSchema(
      id: 2579521892832768574,
      name: r'userInput',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'userInput',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'detectedIntent': IndexSchema(
      id: 1824384453796320716,
      name: r'detectedIntent',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'detectedIntent',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _aiInteractionGetId,
  getLinks: _aiInteractionGetLinks,
  attach: _aiInteractionAttach,
  version: '3.1.0+1',
);

int _aiInteractionEstimateSize(
  AiInteraction object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.correctedIntent;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.detectedIntent.length * 3;
  {
    final value = object.extractedEntitiesJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.userInput.length * 3;
  return bytesCount;
}

void _aiInteractionSerialize(
  AiInteraction object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.confidence);
  writer.writeString(offsets[1], object.correctedIntent);
  writer.writeString(offsets[2], object.detectedIntent);
  writer.writeString(offsets[3], object.extractedEntitiesJson);
  writer.writeDateTime(offsets[4], object.timestamp);
  writer.writeString(offsets[5], object.userInput);
}

AiInteraction _aiInteractionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = AiInteraction(
    confidence: reader.readDoubleOrNull(offsets[0]) ?? 0.0,
    correctedIntent: reader.readStringOrNull(offsets[1]),
    detectedIntent: reader.readString(offsets[2]),
    extractedEntitiesJson: reader.readStringOrNull(offsets[3]),
    timestamp: reader.readDateTime(offsets[4]),
    userInput: reader.readString(offsets[5]),
  );
  object.id = id;
  return object;
}

P _aiInteractionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readDateTime(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _aiInteractionGetId(AiInteraction object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _aiInteractionGetLinks(AiInteraction object) {
  return [];
}

void _aiInteractionAttach(
    IsarCollection<dynamic> col, Id id, AiInteraction object) {
  object.id = id;
}

extension AiInteractionQueryWhereSort
    on QueryBuilder<AiInteraction, AiInteraction, QWhere> {
  QueryBuilder<AiInteraction, AiInteraction, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension AiInteractionQueryWhere
    on QueryBuilder<AiInteraction, AiInteraction, QWhereClause> {
  QueryBuilder<AiInteraction, AiInteraction, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<AiInteraction, AiInteraction, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterWhereClause> idBetween(
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

  QueryBuilder<AiInteraction, AiInteraction, QAfterWhereClause>
      userInputEqualTo(String userInput) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'userInput',
        value: [userInput],
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterWhereClause>
      userInputNotEqualTo(String userInput) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userInput',
              lower: [],
              upper: [userInput],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userInput',
              lower: [userInput],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userInput',
              lower: [userInput],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userInput',
              lower: [],
              upper: [userInput],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterWhereClause>
      detectedIntentEqualTo(String detectedIntent) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'detectedIntent',
        value: [detectedIntent],
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterWhereClause>
      detectedIntentNotEqualTo(String detectedIntent) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'detectedIntent',
              lower: [],
              upper: [detectedIntent],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'detectedIntent',
              lower: [detectedIntent],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'detectedIntent',
              lower: [detectedIntent],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'detectedIntent',
              lower: [],
              upper: [detectedIntent],
              includeUpper: false,
            ));
      }
    });
  }
}

extension AiInteractionQueryFilter
    on QueryBuilder<AiInteraction, AiInteraction, QFilterCondition> {
  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      confidenceEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'confidence',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      confidenceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'confidence',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      confidenceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'confidence',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      confidenceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'confidence',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      correctedIntentIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'correctedIntent',
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      correctedIntentIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'correctedIntent',
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      correctedIntentEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'correctedIntent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      correctedIntentGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'correctedIntent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      correctedIntentLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'correctedIntent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      correctedIntentBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'correctedIntent',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      correctedIntentStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'correctedIntent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      correctedIntentEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'correctedIntent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      correctedIntentContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'correctedIntent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      correctedIntentMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'correctedIntent',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      correctedIntentIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'correctedIntent',
        value: '',
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      correctedIntentIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'correctedIntent',
        value: '',
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      detectedIntentEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'detectedIntent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      detectedIntentGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'detectedIntent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      detectedIntentLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'detectedIntent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      detectedIntentBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'detectedIntent',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      detectedIntentStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'detectedIntent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      detectedIntentEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'detectedIntent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      detectedIntentContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'detectedIntent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      detectedIntentMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'detectedIntent',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      detectedIntentIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'detectedIntent',
        value: '',
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      detectedIntentIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'detectedIntent',
        value: '',
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      extractedEntitiesJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'extractedEntitiesJson',
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      extractedEntitiesJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'extractedEntitiesJson',
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      extractedEntitiesJsonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'extractedEntitiesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      extractedEntitiesJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'extractedEntitiesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      extractedEntitiesJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'extractedEntitiesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      extractedEntitiesJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'extractedEntitiesJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      extractedEntitiesJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'extractedEntitiesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      extractedEntitiesJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'extractedEntitiesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      extractedEntitiesJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'extractedEntitiesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      extractedEntitiesJsonMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'extractedEntitiesJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      extractedEntitiesJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'extractedEntitiesJson',
        value: '',
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      extractedEntitiesJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'extractedEntitiesJson',
        value: '',
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition> idBetween(
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

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      timestampEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      timestampGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      timestampLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      timestampBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timestamp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      userInputEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userInput',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      userInputGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'userInput',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      userInputLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'userInput',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      userInputBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'userInput',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      userInputStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'userInput',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      userInputEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'userInput',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      userInputContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'userInput',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      userInputMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'userInput',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      userInputIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userInput',
        value: '',
      ));
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterFilterCondition>
      userInputIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userInput',
        value: '',
      ));
    });
  }
}

extension AiInteractionQueryObject
    on QueryBuilder<AiInteraction, AiInteraction, QFilterCondition> {}

extension AiInteractionQueryLinks
    on QueryBuilder<AiInteraction, AiInteraction, QFilterCondition> {}

extension AiInteractionQuerySortBy
    on QueryBuilder<AiInteraction, AiInteraction, QSortBy> {
  QueryBuilder<AiInteraction, AiInteraction, QAfterSortBy> sortByConfidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confidence', Sort.asc);
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterSortBy>
      sortByConfidenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confidence', Sort.desc);
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterSortBy>
      sortByCorrectedIntent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'correctedIntent', Sort.asc);
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterSortBy>
      sortByCorrectedIntentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'correctedIntent', Sort.desc);
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterSortBy>
      sortByDetectedIntent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'detectedIntent', Sort.asc);
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterSortBy>
      sortByDetectedIntentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'detectedIntent', Sort.desc);
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterSortBy>
      sortByExtractedEntitiesJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'extractedEntitiesJson', Sort.asc);
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterSortBy>
      sortByExtractedEntitiesJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'extractedEntitiesJson', Sort.desc);
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterSortBy> sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterSortBy>
      sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterSortBy> sortByUserInput() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userInput', Sort.asc);
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterSortBy>
      sortByUserInputDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userInput', Sort.desc);
    });
  }
}

extension AiInteractionQuerySortThenBy
    on QueryBuilder<AiInteraction, AiInteraction, QSortThenBy> {
  QueryBuilder<AiInteraction, AiInteraction, QAfterSortBy> thenByConfidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confidence', Sort.asc);
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterSortBy>
      thenByConfidenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confidence', Sort.desc);
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterSortBy>
      thenByCorrectedIntent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'correctedIntent', Sort.asc);
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterSortBy>
      thenByCorrectedIntentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'correctedIntent', Sort.desc);
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterSortBy>
      thenByDetectedIntent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'detectedIntent', Sort.asc);
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterSortBy>
      thenByDetectedIntentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'detectedIntent', Sort.desc);
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterSortBy>
      thenByExtractedEntitiesJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'extractedEntitiesJson', Sort.asc);
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterSortBy>
      thenByExtractedEntitiesJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'extractedEntitiesJson', Sort.desc);
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterSortBy> thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterSortBy>
      thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterSortBy> thenByUserInput() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userInput', Sort.asc);
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QAfterSortBy>
      thenByUserInputDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userInput', Sort.desc);
    });
  }
}

extension AiInteractionQueryWhereDistinct
    on QueryBuilder<AiInteraction, AiInteraction, QDistinct> {
  QueryBuilder<AiInteraction, AiInteraction, QDistinct> distinctByConfidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'confidence');
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QDistinct>
      distinctByCorrectedIntent({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'correctedIntent',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QDistinct>
      distinctByDetectedIntent({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'detectedIntent',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QDistinct>
      distinctByExtractedEntitiesJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'extractedEntitiesJson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QDistinct> distinctByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timestamp');
    });
  }

  QueryBuilder<AiInteraction, AiInteraction, QDistinct> distinctByUserInput(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userInput', caseSensitive: caseSensitive);
    });
  }
}

extension AiInteractionQueryProperty
    on QueryBuilder<AiInteraction, AiInteraction, QQueryProperty> {
  QueryBuilder<AiInteraction, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<AiInteraction, double, QQueryOperations> confidenceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'confidence');
    });
  }

  QueryBuilder<AiInteraction, String?, QQueryOperations>
      correctedIntentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'correctedIntent');
    });
  }

  QueryBuilder<AiInteraction, String, QQueryOperations>
      detectedIntentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'detectedIntent');
    });
  }

  QueryBuilder<AiInteraction, String?, QQueryOperations>
      extractedEntitiesJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'extractedEntitiesJson');
    });
  }

  QueryBuilder<AiInteraction, DateTime, QQueryOperations> timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestamp');
    });
  }

  QueryBuilder<AiInteraction, String, QQueryOperations> userInputProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userInput');
    });
  }
}
