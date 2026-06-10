// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'keep_note_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetKeepNoteCollection on Isar {
  IsarCollection<KeepNote> get keepNotes => this.collection();
}

const KeepNoteSchema = CollectionSchema(
  name: r'KeepNote',
  id: 2621117444478627819,
  properties: {
    r'attachments': PropertySchema(
      id: 0,
      name: r'attachments',
      type: IsarType.objectList,

      target: r'KeepAttachment',
    ),
    r'backgroundBlur': PropertySchema(
      id: 1,
      name: r'backgroundBlur',
      type: IsarType.double,
    ),
    r'backgroundIndex': PropertySchema(
      id: 2,
      name: r'backgroundIndex',
      type: IsarType.long,
    ),
    r'checkItems': PropertySchema(
      id: 3,
      name: r'checkItems',
      type: IsarType.objectList,

      target: r'KeepCheckItem',
    ),
    r'colorIndex': PropertySchema(
      id: 4,
      name: r'colorIndex',
      type: IsarType.long,
    ),
    r'content': PropertySchema(id: 5, name: r'content', type: IsarType.string),
    r'createdAt': PropertySchema(
      id: 6,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'isBold': PropertySchema(id: 7, name: r'isBold', type: IsarType.bool),
    r'isItalic': PropertySchema(id: 8, name: r'isItalic', type: IsarType.bool),
    r'isPinned': PropertySchema(id: 9, name: r'isPinned', type: IsarType.bool),
    r'isUnderline': PropertySchema(
      id: 10,
      name: r'isUnderline',
      type: IsarType.bool,
    ),
    r'linkedItemId': PropertySchema(
      id: 11,
      name: r'linkedItemId',
      type: IsarType.long,
    ),
    r'linkedItemType': PropertySchema(
      id: 12,
      name: r'linkedItemType',
      type: IsarType.string,
    ),
    r'pinnedSort': PropertySchema(
      id: 13,
      name: r'pinnedSort',
      type: IsarType.bool,
    ),
    r'reminderAt': PropertySchema(
      id: 14,
      name: r'reminderAt',
      type: IsarType.dateTime,
    ),
    r'reminderDone': PropertySchema(
      id: 15,
      name: r'reminderDone',
      type: IsarType.bool,
    ),
    r'sortOrder': PropertySchema(
      id: 16,
      name: r'sortOrder',
      type: IsarType.double,
    ),
    r'tags': PropertySchema(id: 17, name: r'tags', type: IsarType.stringList),
    r'textAlign': PropertySchema(
      id: 18,
      name: r'textAlign',
      type: IsarType.long,
    ),
    r'textColorIndex': PropertySchema(
      id: 19,
      name: r'textColorIndex',
      type: IsarType.long,
    ),
    r'textSize': PropertySchema(
      id: 20,
      name: r'textSize',
      type: IsarType.double,
    ),
    r'title': PropertySchema(id: 21, name: r'title', type: IsarType.string),
    r'updatedAt': PropertySchema(
      id: 22,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
  },

  estimateSize: _keepNoteEstimateSize,
  serialize: _keepNoteSerialize,
  deserialize: _keepNoteDeserialize,
  deserializeProp: _keepNoteDeserializeProp,
  idName: r'id',
  indexes: {
    r'title': IndexSchema(
      id: -7636685945352118059,
      name: r'title',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'title',
          type: IndexType.value,
          caseSensitive: true,
        ),
      ],
    ),
    r'reminderAt': IndexSchema(
      id: -2650462151190739050,
      name: r'reminderAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'reminderAt',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'pinnedSort_sortOrder': IndexSchema(
      id: -2117345797378077203,
      name: r'pinnedSort_sortOrder',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'pinnedSort',
          type: IndexType.value,
          caseSensitive: false,
        ),
        IndexPropertySchema(
          name: r'sortOrder',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {
    r'KeepCheckItem': KeepCheckItemSchema,
    r'KeepAttachment': KeepAttachmentSchema,
  },

  getId: _keepNoteGetId,
  getLinks: _keepNoteGetLinks,
  attach: _keepNoteAttach,
  version: '3.3.2',
);

int _keepNoteEstimateSize(
  KeepNote object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.attachments.length * 3;
  {
    final offsets = allOffsets[KeepAttachment]!;
    for (var i = 0; i < object.attachments.length; i++) {
      final value = object.attachments[i];
      bytesCount += KeepAttachmentSchema.estimateSize(
        value,
        offsets,
        allOffsets,
      );
    }
  }
  bytesCount += 3 + object.checkItems.length * 3;
  {
    final offsets = allOffsets[KeepCheckItem]!;
    for (var i = 0; i < object.checkItems.length; i++) {
      final value = object.checkItems[i];
      bytesCount += KeepCheckItemSchema.estimateSize(
        value,
        offsets,
        allOffsets,
      );
    }
  }
  {
    final value = object.content;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.linkedItemType;
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
  return bytesCount;
}

void _keepNoteSerialize(
  KeepNote object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeObjectList<KeepAttachment>(
    offsets[0],
    allOffsets,
    KeepAttachmentSchema.serialize,
    object.attachments,
  );
  writer.writeDouble(offsets[1], object.backgroundBlur);
  writer.writeLong(offsets[2], object.backgroundIndex);
  writer.writeObjectList<KeepCheckItem>(
    offsets[3],
    allOffsets,
    KeepCheckItemSchema.serialize,
    object.checkItems,
  );
  writer.writeLong(offsets[4], object.colorIndex);
  writer.writeString(offsets[5], object.content);
  writer.writeDateTime(offsets[6], object.createdAt);
  writer.writeBool(offsets[7], object.isBold);
  writer.writeBool(offsets[8], object.isItalic);
  writer.writeBool(offsets[9], object.isPinned);
  writer.writeBool(offsets[10], object.isUnderline);
  writer.writeLong(offsets[11], object.linkedItemId);
  writer.writeString(offsets[12], object.linkedItemType);
  writer.writeBool(offsets[13], object.pinnedSort);
  writer.writeDateTime(offsets[14], object.reminderAt);
  writer.writeBool(offsets[15], object.reminderDone);
  writer.writeDouble(offsets[16], object.sortOrder);
  writer.writeStringList(offsets[17], object.tags);
  writer.writeLong(offsets[18], object.textAlign);
  writer.writeLong(offsets[19], object.textColorIndex);
  writer.writeDouble(offsets[20], object.textSize);
  writer.writeString(offsets[21], object.title);
  writer.writeDateTime(offsets[22], object.updatedAt);
}

KeepNote _keepNoteDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = KeepNote();
  object.attachments =
      reader.readObjectList<KeepAttachment>(
        offsets[0],
        KeepAttachmentSchema.deserialize,
        allOffsets,
        KeepAttachment(),
      ) ??
      [];
  object.backgroundBlur = reader.readDouble(offsets[1]);
  object.backgroundIndex = reader.readLongOrNull(offsets[2]);
  object.checkItems =
      reader.readObjectList<KeepCheckItem>(
        offsets[3],
        KeepCheckItemSchema.deserialize,
        allOffsets,
        KeepCheckItem(),
      ) ??
      [];
  object.colorIndex = reader.readLongOrNull(offsets[4]);
  object.content = reader.readStringOrNull(offsets[5]);
  object.createdAt = reader.readDateTime(offsets[6]);
  object.id = id;
  object.isBold = reader.readBool(offsets[7]);
  object.isItalic = reader.readBool(offsets[8]);
  object.isPinned = reader.readBool(offsets[9]);
  object.isUnderline = reader.readBool(offsets[10]);
  object.linkedItemId = reader.readLongOrNull(offsets[11]);
  object.linkedItemType = reader.readStringOrNull(offsets[12]);
  object.reminderAt = reader.readDateTimeOrNull(offsets[14]);
  object.reminderDone = reader.readBool(offsets[15]);
  object.sortOrder = reader.readDouble(offsets[16]);
  object.tags = reader.readStringList(offsets[17]) ?? [];
  object.textAlign = reader.readLong(offsets[18]);
  object.textColorIndex = reader.readLongOrNull(offsets[19]);
  object.textSize = reader.readDouble(offsets[20]);
  object.title = reader.readString(offsets[21]);
  object.updatedAt = reader.readDateTimeOrNull(offsets[22]);
  return object;
}

P _keepNoteDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readObjectList<KeepAttachment>(
                offset,
                KeepAttachmentSchema.deserialize,
                allOffsets,
                KeepAttachment(),
              ) ??
              [])
          as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    case 2:
      return (reader.readLongOrNull(offset)) as P;
    case 3:
      return (reader.readObjectList<KeepCheckItem>(
                offset,
                KeepCheckItemSchema.deserialize,
                allOffsets,
                KeepCheckItem(),
              ) ??
              [])
          as P;
    case 4:
      return (reader.readLongOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readDateTime(offset)) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    case 8:
      return (reader.readBool(offset)) as P;
    case 9:
      return (reader.readBool(offset)) as P;
    case 10:
      return (reader.readBool(offset)) as P;
    case 11:
      return (reader.readLongOrNull(offset)) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readBool(offset)) as P;
    case 14:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 15:
      return (reader.readBool(offset)) as P;
    case 16:
      return (reader.readDouble(offset)) as P;
    case 17:
      return (reader.readStringList(offset) ?? []) as P;
    case 18:
      return (reader.readLong(offset)) as P;
    case 19:
      return (reader.readLongOrNull(offset)) as P;
    case 20:
      return (reader.readDouble(offset)) as P;
    case 21:
      return (reader.readString(offset)) as P;
    case 22:
      return (reader.readDateTimeOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _keepNoteGetId(KeepNote object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _keepNoteGetLinks(KeepNote object) {
  return [];
}

void _keepNoteAttach(IsarCollection<dynamic> col, Id id, KeepNote object) {
  object.id = id;
}

extension KeepNoteQueryWhereSort on QueryBuilder<KeepNote, KeepNote, QWhere> {
  QueryBuilder<KeepNote, KeepNote, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterWhere> anyTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'title'),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterWhere> anyReminderAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'reminderAt'),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterWhere> anyPinnedSortSortOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'pinnedSort_sortOrder'),
      );
    });
  }
}

extension KeepNoteQueryWhere on QueryBuilder<KeepNote, KeepNote, QWhereClause> {
  QueryBuilder<KeepNote, KeepNote, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<KeepNote, KeepNote, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterWhereClause> titleEqualTo(
    String title,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'title', value: [title]),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterWhereClause> titleNotEqualTo(
    String title,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'title',
                lower: [],
                upper: [title],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'title',
                lower: [title],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'title',
                lower: [title],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'title',
                lower: [],
                upper: [title],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterWhereClause> titleGreaterThan(
    String title, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'title',
          lower: [title],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterWhereClause> titleLessThan(
    String title, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'title',
          lower: [],
          upper: [title],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterWhereClause> titleBetween(
    String lowerTitle,
    String upperTitle, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'title',
          lower: [lowerTitle],
          includeLower: includeLower,
          upper: [upperTitle],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterWhereClause> titleStartsWith(
    String TitlePrefix,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'title',
          lower: [TitlePrefix],
          upper: ['$TitlePrefix\u{FFFFF}'],
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterWhereClause> titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'title', value: ['']),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterWhereClause> titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.lessThan(indexName: r'title', upper: ['']),
            )
            .addWhereClause(
              IndexWhereClause.greaterThan(indexName: r'title', lower: ['']),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.greaterThan(indexName: r'title', lower: ['']),
            )
            .addWhereClause(
              IndexWhereClause.lessThan(indexName: r'title', upper: ['']),
            );
      }
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterWhereClause> reminderAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'reminderAt', value: [null]),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterWhereClause> reminderAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'reminderAt',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterWhereClause> reminderAtEqualTo(
    DateTime? reminderAt,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'reminderAt', value: [reminderAt]),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterWhereClause> reminderAtNotEqualTo(
    DateTime? reminderAt,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'reminderAt',
                lower: [],
                upper: [reminderAt],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'reminderAt',
                lower: [reminderAt],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'reminderAt',
                lower: [reminderAt],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'reminderAt',
                lower: [],
                upper: [reminderAt],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterWhereClause> reminderAtGreaterThan(
    DateTime? reminderAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'reminderAt',
          lower: [reminderAt],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterWhereClause> reminderAtLessThan(
    DateTime? reminderAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'reminderAt',
          lower: [],
          upper: [reminderAt],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterWhereClause> reminderAtBetween(
    DateTime? lowerReminderAt,
    DateTime? upperReminderAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'reminderAt',
          lower: [lowerReminderAt],
          includeLower: includeLower,
          upper: [upperReminderAt],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterWhereClause>
  pinnedSortEqualToAnySortOrder(bool pinnedSort) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'pinnedSort_sortOrder',
          value: [pinnedSort],
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterWhereClause>
  pinnedSortNotEqualToAnySortOrder(bool pinnedSort) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'pinnedSort_sortOrder',
                lower: [],
                upper: [pinnedSort],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'pinnedSort_sortOrder',
                lower: [pinnedSort],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'pinnedSort_sortOrder',
                lower: [pinnedSort],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'pinnedSort_sortOrder',
                lower: [],
                upper: [pinnedSort],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterWhereClause>
  pinnedSortSortOrderEqualTo(bool pinnedSort, double sortOrder) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'pinnedSort_sortOrder',
          value: [pinnedSort, sortOrder],
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterWhereClause>
  pinnedSortEqualToSortOrderNotEqualTo(bool pinnedSort, double sortOrder) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'pinnedSort_sortOrder',
                lower: [pinnedSort],
                upper: [pinnedSort, sortOrder],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'pinnedSort_sortOrder',
                lower: [pinnedSort, sortOrder],
                includeLower: false,
                upper: [pinnedSort],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'pinnedSort_sortOrder',
                lower: [pinnedSort, sortOrder],
                includeLower: false,
                upper: [pinnedSort],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'pinnedSort_sortOrder',
                lower: [pinnedSort],
                upper: [pinnedSort, sortOrder],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterWhereClause>
  pinnedSortEqualToSortOrderGreaterThan(
    bool pinnedSort,
    double sortOrder, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'pinnedSort_sortOrder',
          lower: [pinnedSort, sortOrder],
          includeLower: include,
          upper: [pinnedSort],
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterWhereClause>
  pinnedSortEqualToSortOrderLessThan(
    bool pinnedSort,
    double sortOrder, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'pinnedSort_sortOrder',
          lower: [pinnedSort],
          upper: [pinnedSort, sortOrder],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterWhereClause>
  pinnedSortEqualToSortOrderBetween(
    bool pinnedSort,
    double lowerSortOrder,
    double upperSortOrder, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'pinnedSort_sortOrder',
          lower: [pinnedSort, lowerSortOrder],
          includeLower: includeLower,
          upper: [pinnedSort, upperSortOrder],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension KeepNoteQueryFilter
    on QueryBuilder<KeepNote, KeepNote, QFilterCondition> {
  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition>
  attachmentsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'attachments', length, true, length, true);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> attachmentsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'attachments', 0, true, 0, true);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition>
  attachmentsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'attachments', 0, false, 999999, true);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition>
  attachmentsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'attachments', 0, true, length, include);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition>
  attachmentsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'attachments', length, include, 999999, true);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition>
  attachmentsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'attachments',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> backgroundBlurEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'backgroundBlur',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition>
  backgroundBlurGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'backgroundBlur',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition>
  backgroundBlurLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'backgroundBlur',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> backgroundBlurBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'backgroundBlur',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition>
  backgroundIndexIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'backgroundIndex'),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition>
  backgroundIndexIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'backgroundIndex'),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition>
  backgroundIndexEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'backgroundIndex', value: value),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition>
  backgroundIndexGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'backgroundIndex',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition>
  backgroundIndexLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'backgroundIndex',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition>
  backgroundIndexBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'backgroundIndex',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition>
  checkItemsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'checkItems', length, true, length, true);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> checkItemsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'checkItems', 0, true, 0, true);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition>
  checkItemsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'checkItems', 0, false, 999999, true);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition>
  checkItemsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'checkItems', 0, true, length, include);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition>
  checkItemsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'checkItems', length, include, 999999, true);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition>
  checkItemsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'checkItems',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> colorIndexIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'colorIndex'),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition>
  colorIndexIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'colorIndex'),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> colorIndexEqualTo(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'colorIndex', value: value),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> colorIndexGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'colorIndex',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> colorIndexLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'colorIndex',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> colorIndexBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'colorIndex',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> contentIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'content'),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> contentIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'content'),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> contentEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'content',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> contentGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'content',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> contentLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'content',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> contentBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'content',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> contentStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'content',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> contentEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'content',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> contentContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'content',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> contentMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'content',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> contentIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'content', value: ''),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> contentIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'content', value: ''),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> createdAtEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'createdAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> isBoldEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isBold', value: value),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> isItalicEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isItalic', value: value),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> isPinnedEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isPinned', value: value),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> isUnderlineEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isUnderline', value: value),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> linkedItemIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'linkedItemId'),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition>
  linkedItemIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'linkedItemId'),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> linkedItemIdEqualTo(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'linkedItemId', value: value),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition>
  linkedItemIdGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'linkedItemId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> linkedItemIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'linkedItemId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> linkedItemIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'linkedItemId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition>
  linkedItemTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'linkedItemType'),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition>
  linkedItemTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'linkedItemType'),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> linkedItemTypeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'linkedItemType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition>
  linkedItemTypeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'linkedItemType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition>
  linkedItemTypeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'linkedItemType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> linkedItemTypeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'linkedItemType',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition>
  linkedItemTypeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'linkedItemType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition>
  linkedItemTypeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'linkedItemType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition>
  linkedItemTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'linkedItemType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> linkedItemTypeMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'linkedItemType',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition>
  linkedItemTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'linkedItemType', value: ''),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition>
  linkedItemTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'linkedItemType', value: ''),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> pinnedSortEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'pinnedSort', value: value),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> reminderAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'reminderAt'),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition>
  reminderAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'reminderAt'),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> reminderAtEqualTo(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'reminderAt', value: value),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> reminderAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'reminderAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> reminderAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'reminderAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> reminderAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'reminderAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> reminderDoneEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'reminderDone', value: value),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> sortOrderEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sortOrder',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> sortOrderGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sortOrder',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> sortOrderLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sortOrder',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> sortOrderBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sortOrder',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> tagsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'tags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition>
  tagsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'tags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> tagsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'tags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> tagsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'tags',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> tagsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'tags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> tagsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'tags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> tagsElementContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'tags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> tagsElementMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'tags',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> tagsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'tags', value: ''),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition>
  tagsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'tags', value: ''),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> tagsLengthEqualTo(
    int length,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tags', length, true, length, true);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> tagsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tags', 0, true, 0, true);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> tagsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tags', 0, false, 999999, true);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> tagsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tags', 0, true, length, include);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> tagsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tags', length, include, 999999, true);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> tagsLengthBetween(
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

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> textAlignEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'textAlign', value: value),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> textAlignGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'textAlign',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> textAlignLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'textAlign',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> textAlignBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'textAlign',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition>
  textColorIndexIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'textColorIndex'),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition>
  textColorIndexIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'textColorIndex'),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> textColorIndexEqualTo(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'textColorIndex', value: value),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition>
  textColorIndexGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'textColorIndex',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition>
  textColorIndexLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'textColorIndex',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> textColorIndexBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'textColorIndex',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> textSizeEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'textSize',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> textSizeGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'textSize',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> textSizeLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'textSize',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> textSizeBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'textSize',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> titleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'title',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> titleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> titleContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> titleMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'title',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> updatedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'updatedAt'),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> updatedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'updatedAt'),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> updatedAtEqualTo(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> updatedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> updatedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> updatedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'updatedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension KeepNoteQueryObject
    on QueryBuilder<KeepNote, KeepNote, QFilterCondition> {
  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> attachmentsElement(
    FilterQuery<KeepAttachment> q,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'attachments');
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterFilterCondition> checkItemsElement(
    FilterQuery<KeepCheckItem> q,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'checkItems');
    });
  }
}

extension KeepNoteQueryLinks
    on QueryBuilder<KeepNote, KeepNote, QFilterCondition> {}

extension KeepNoteQuerySortBy on QueryBuilder<KeepNote, KeepNote, QSortBy> {
  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> sortByBackgroundBlur() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'backgroundBlur', Sort.asc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> sortByBackgroundBlurDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'backgroundBlur', Sort.desc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> sortByBackgroundIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'backgroundIndex', Sort.asc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> sortByBackgroundIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'backgroundIndex', Sort.desc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> sortByColorIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorIndex', Sort.asc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> sortByColorIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorIndex', Sort.desc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> sortByContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.asc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> sortByContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.desc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> sortByIsBold() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isBold', Sort.asc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> sortByIsBoldDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isBold', Sort.desc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> sortByIsItalic() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isItalic', Sort.asc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> sortByIsItalicDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isItalic', Sort.desc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> sortByIsPinned() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPinned', Sort.asc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> sortByIsPinnedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPinned', Sort.desc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> sortByIsUnderline() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUnderline', Sort.asc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> sortByIsUnderlineDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUnderline', Sort.desc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> sortByLinkedItemId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'linkedItemId', Sort.asc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> sortByLinkedItemIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'linkedItemId', Sort.desc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> sortByLinkedItemType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'linkedItemType', Sort.asc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> sortByLinkedItemTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'linkedItemType', Sort.desc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> sortByPinnedSort() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pinnedSort', Sort.asc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> sortByPinnedSortDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pinnedSort', Sort.desc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> sortByReminderAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reminderAt', Sort.asc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> sortByReminderAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reminderAt', Sort.desc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> sortByReminderDone() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reminderDone', Sort.asc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> sortByReminderDoneDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reminderDone', Sort.desc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> sortBySortOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sortOrder', Sort.asc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> sortBySortOrderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sortOrder', Sort.desc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> sortByTextAlign() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textAlign', Sort.asc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> sortByTextAlignDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textAlign', Sort.desc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> sortByTextColorIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textColorIndex', Sort.asc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> sortByTextColorIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textColorIndex', Sort.desc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> sortByTextSize() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textSize', Sort.asc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> sortByTextSizeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textSize', Sort.desc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension KeepNoteQuerySortThenBy
    on QueryBuilder<KeepNote, KeepNote, QSortThenBy> {
  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> thenByBackgroundBlur() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'backgroundBlur', Sort.asc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> thenByBackgroundBlurDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'backgroundBlur', Sort.desc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> thenByBackgroundIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'backgroundIndex', Sort.asc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> thenByBackgroundIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'backgroundIndex', Sort.desc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> thenByColorIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorIndex', Sort.asc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> thenByColorIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorIndex', Sort.desc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> thenByContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.asc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> thenByContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.desc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> thenByIsBold() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isBold', Sort.asc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> thenByIsBoldDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isBold', Sort.desc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> thenByIsItalic() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isItalic', Sort.asc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> thenByIsItalicDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isItalic', Sort.desc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> thenByIsPinned() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPinned', Sort.asc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> thenByIsPinnedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPinned', Sort.desc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> thenByIsUnderline() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUnderline', Sort.asc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> thenByIsUnderlineDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUnderline', Sort.desc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> thenByLinkedItemId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'linkedItemId', Sort.asc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> thenByLinkedItemIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'linkedItemId', Sort.desc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> thenByLinkedItemType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'linkedItemType', Sort.asc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> thenByLinkedItemTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'linkedItemType', Sort.desc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> thenByPinnedSort() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pinnedSort', Sort.asc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> thenByPinnedSortDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pinnedSort', Sort.desc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> thenByReminderAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reminderAt', Sort.asc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> thenByReminderAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reminderAt', Sort.desc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> thenByReminderDone() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reminderDone', Sort.asc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> thenByReminderDoneDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reminderDone', Sort.desc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> thenBySortOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sortOrder', Sort.asc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> thenBySortOrderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sortOrder', Sort.desc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> thenByTextAlign() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textAlign', Sort.asc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> thenByTextAlignDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textAlign', Sort.desc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> thenByTextColorIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textColorIndex', Sort.asc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> thenByTextColorIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textColorIndex', Sort.desc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> thenByTextSize() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textSize', Sort.asc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> thenByTextSizeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textSize', Sort.desc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension KeepNoteQueryWhereDistinct
    on QueryBuilder<KeepNote, KeepNote, QDistinct> {
  QueryBuilder<KeepNote, KeepNote, QDistinct> distinctByBackgroundBlur() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'backgroundBlur');
    });
  }

  QueryBuilder<KeepNote, KeepNote, QDistinct> distinctByBackgroundIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'backgroundIndex');
    });
  }

  QueryBuilder<KeepNote, KeepNote, QDistinct> distinctByColorIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'colorIndex');
    });
  }

  QueryBuilder<KeepNote, KeepNote, QDistinct> distinctByContent({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'content', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<KeepNote, KeepNote, QDistinct> distinctByIsBold() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isBold');
    });
  }

  QueryBuilder<KeepNote, KeepNote, QDistinct> distinctByIsItalic() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isItalic');
    });
  }

  QueryBuilder<KeepNote, KeepNote, QDistinct> distinctByIsPinned() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isPinned');
    });
  }

  QueryBuilder<KeepNote, KeepNote, QDistinct> distinctByIsUnderline() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isUnderline');
    });
  }

  QueryBuilder<KeepNote, KeepNote, QDistinct> distinctByLinkedItemId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'linkedItemId');
    });
  }

  QueryBuilder<KeepNote, KeepNote, QDistinct> distinctByLinkedItemType({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'linkedItemType',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<KeepNote, KeepNote, QDistinct> distinctByPinnedSort() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pinnedSort');
    });
  }

  QueryBuilder<KeepNote, KeepNote, QDistinct> distinctByReminderAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reminderAt');
    });
  }

  QueryBuilder<KeepNote, KeepNote, QDistinct> distinctByReminderDone() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reminderDone');
    });
  }

  QueryBuilder<KeepNote, KeepNote, QDistinct> distinctBySortOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sortOrder');
    });
  }

  QueryBuilder<KeepNote, KeepNote, QDistinct> distinctByTags() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tags');
    });
  }

  QueryBuilder<KeepNote, KeepNote, QDistinct> distinctByTextAlign() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'textAlign');
    });
  }

  QueryBuilder<KeepNote, KeepNote, QDistinct> distinctByTextColorIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'textColorIndex');
    });
  }

  QueryBuilder<KeepNote, KeepNote, QDistinct> distinctByTextSize() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'textSize');
    });
  }

  QueryBuilder<KeepNote, KeepNote, QDistinct> distinctByTitle({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<KeepNote, KeepNote, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension KeepNoteQueryProperty
    on QueryBuilder<KeepNote, KeepNote, QQueryProperty> {
  QueryBuilder<KeepNote, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<KeepNote, List<KeepAttachment>, QQueryOperations>
  attachmentsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'attachments');
    });
  }

  QueryBuilder<KeepNote, double, QQueryOperations> backgroundBlurProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'backgroundBlur');
    });
  }

  QueryBuilder<KeepNote, int?, QQueryOperations> backgroundIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'backgroundIndex');
    });
  }

  QueryBuilder<KeepNote, List<KeepCheckItem>, QQueryOperations>
  checkItemsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'checkItems');
    });
  }

  QueryBuilder<KeepNote, int?, QQueryOperations> colorIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'colorIndex');
    });
  }

  QueryBuilder<KeepNote, String?, QQueryOperations> contentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'content');
    });
  }

  QueryBuilder<KeepNote, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<KeepNote, bool, QQueryOperations> isBoldProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isBold');
    });
  }

  QueryBuilder<KeepNote, bool, QQueryOperations> isItalicProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isItalic');
    });
  }

  QueryBuilder<KeepNote, bool, QQueryOperations> isPinnedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isPinned');
    });
  }

  QueryBuilder<KeepNote, bool, QQueryOperations> isUnderlineProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isUnderline');
    });
  }

  QueryBuilder<KeepNote, int?, QQueryOperations> linkedItemIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'linkedItemId');
    });
  }

  QueryBuilder<KeepNote, String?, QQueryOperations> linkedItemTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'linkedItemType');
    });
  }

  QueryBuilder<KeepNote, bool, QQueryOperations> pinnedSortProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pinnedSort');
    });
  }

  QueryBuilder<KeepNote, DateTime?, QQueryOperations> reminderAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reminderAt');
    });
  }

  QueryBuilder<KeepNote, bool, QQueryOperations> reminderDoneProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reminderDone');
    });
  }

  QueryBuilder<KeepNote, double, QQueryOperations> sortOrderProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sortOrder');
    });
  }

  QueryBuilder<KeepNote, List<String>, QQueryOperations> tagsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tags');
    });
  }

  QueryBuilder<KeepNote, int, QQueryOperations> textAlignProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'textAlign');
    });
  }

  QueryBuilder<KeepNote, int?, QQueryOperations> textColorIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'textColorIndex');
    });
  }

  QueryBuilder<KeepNote, double, QQueryOperations> textSizeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'textSize');
    });
  }

  QueryBuilder<KeepNote, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<KeepNote, DateTime?, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const KeepAttachmentSchema = Schema(
  name: r'KeepAttachment',
  id: -5536732741957974184,
  properties: {
    r'durationMs': PropertySchema(
      id: 0,
      name: r'durationMs',
      type: IsarType.long,
    ),
    r'relativePath': PropertySchema(
      id: 1,
      name: r'relativePath',
      type: IsarType.string,
    ),
    r'sortIndex': PropertySchema(
      id: 2,
      name: r'sortIndex',
      type: IsarType.long,
    ),
    r'thumbPath': PropertySchema(
      id: 3,
      name: r'thumbPath',
      type: IsarType.string,
    ),
    r'type': PropertySchema(id: 4, name: r'type', type: IsarType.string),
  },

  estimateSize: _keepAttachmentEstimateSize,
  serialize: _keepAttachmentSerialize,
  deserialize: _keepAttachmentDeserialize,
  deserializeProp: _keepAttachmentDeserializeProp,
);

int _keepAttachmentEstimateSize(
  KeepAttachment object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.relativePath.length * 3;
  {
    final value = object.thumbPath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.type.length * 3;
  return bytesCount;
}

void _keepAttachmentSerialize(
  KeepAttachment object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.durationMs);
  writer.writeString(offsets[1], object.relativePath);
  writer.writeLong(offsets[2], object.sortIndex);
  writer.writeString(offsets[3], object.thumbPath);
  writer.writeString(offsets[4], object.type);
}

KeepAttachment _keepAttachmentDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = KeepAttachment();
  object.durationMs = reader.readLongOrNull(offsets[0]);
  object.relativePath = reader.readString(offsets[1]);
  object.sortIndex = reader.readLong(offsets[2]);
  object.thumbPath = reader.readStringOrNull(offsets[3]);
  object.type = reader.readString(offsets[4]);
  return object;
}

P _keepAttachmentDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension KeepAttachmentQueryFilter
    on QueryBuilder<KeepAttachment, KeepAttachment, QFilterCondition> {
  QueryBuilder<KeepAttachment, KeepAttachment, QAfterFilterCondition>
  durationMsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'durationMs'),
      );
    });
  }

  QueryBuilder<KeepAttachment, KeepAttachment, QAfterFilterCondition>
  durationMsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'durationMs'),
      );
    });
  }

  QueryBuilder<KeepAttachment, KeepAttachment, QAfterFilterCondition>
  durationMsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'durationMs', value: value),
      );
    });
  }

  QueryBuilder<KeepAttachment, KeepAttachment, QAfterFilterCondition>
  durationMsGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'durationMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<KeepAttachment, KeepAttachment, QAfterFilterCondition>
  durationMsLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'durationMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<KeepAttachment, KeepAttachment, QAfterFilterCondition>
  durationMsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'durationMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<KeepAttachment, KeepAttachment, QAfterFilterCondition>
  relativePathEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'relativePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepAttachment, KeepAttachment, QAfterFilterCondition>
  relativePathGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'relativePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepAttachment, KeepAttachment, QAfterFilterCondition>
  relativePathLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'relativePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepAttachment, KeepAttachment, QAfterFilterCondition>
  relativePathBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'relativePath',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepAttachment, KeepAttachment, QAfterFilterCondition>
  relativePathStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'relativePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepAttachment, KeepAttachment, QAfterFilterCondition>
  relativePathEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'relativePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepAttachment, KeepAttachment, QAfterFilterCondition>
  relativePathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'relativePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepAttachment, KeepAttachment, QAfterFilterCondition>
  relativePathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'relativePath',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepAttachment, KeepAttachment, QAfterFilterCondition>
  relativePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'relativePath', value: ''),
      );
    });
  }

  QueryBuilder<KeepAttachment, KeepAttachment, QAfterFilterCondition>
  relativePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'relativePath', value: ''),
      );
    });
  }

  QueryBuilder<KeepAttachment, KeepAttachment, QAfterFilterCondition>
  sortIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sortIndex', value: value),
      );
    });
  }

  QueryBuilder<KeepAttachment, KeepAttachment, QAfterFilterCondition>
  sortIndexGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sortIndex',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<KeepAttachment, KeepAttachment, QAfterFilterCondition>
  sortIndexLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sortIndex',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<KeepAttachment, KeepAttachment, QAfterFilterCondition>
  sortIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sortIndex',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<KeepAttachment, KeepAttachment, QAfterFilterCondition>
  thumbPathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'thumbPath'),
      );
    });
  }

  QueryBuilder<KeepAttachment, KeepAttachment, QAfterFilterCondition>
  thumbPathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'thumbPath'),
      );
    });
  }

  QueryBuilder<KeepAttachment, KeepAttachment, QAfterFilterCondition>
  thumbPathEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'thumbPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepAttachment, KeepAttachment, QAfterFilterCondition>
  thumbPathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'thumbPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepAttachment, KeepAttachment, QAfterFilterCondition>
  thumbPathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'thumbPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepAttachment, KeepAttachment, QAfterFilterCondition>
  thumbPathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'thumbPath',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepAttachment, KeepAttachment, QAfterFilterCondition>
  thumbPathStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'thumbPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepAttachment, KeepAttachment, QAfterFilterCondition>
  thumbPathEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'thumbPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepAttachment, KeepAttachment, QAfterFilterCondition>
  thumbPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'thumbPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepAttachment, KeepAttachment, QAfterFilterCondition>
  thumbPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'thumbPath',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepAttachment, KeepAttachment, QAfterFilterCondition>
  thumbPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'thumbPath', value: ''),
      );
    });
  }

  QueryBuilder<KeepAttachment, KeepAttachment, QAfterFilterCondition>
  thumbPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'thumbPath', value: ''),
      );
    });
  }

  QueryBuilder<KeepAttachment, KeepAttachment, QAfterFilterCondition>
  typeEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepAttachment, KeepAttachment, QAfterFilterCondition>
  typeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepAttachment, KeepAttachment, QAfterFilterCondition>
  typeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepAttachment, KeepAttachment, QAfterFilterCondition>
  typeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'type',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepAttachment, KeepAttachment, QAfterFilterCondition>
  typeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepAttachment, KeepAttachment, QAfterFilterCondition>
  typeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepAttachment, KeepAttachment, QAfterFilterCondition>
  typeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepAttachment, KeepAttachment, QAfterFilterCondition>
  typeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'type',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepAttachment, KeepAttachment, QAfterFilterCondition>
  typeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'type', value: ''),
      );
    });
  }

  QueryBuilder<KeepAttachment, KeepAttachment, QAfterFilterCondition>
  typeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'type', value: ''),
      );
    });
  }
}

extension KeepAttachmentQueryObject
    on QueryBuilder<KeepAttachment, KeepAttachment, QFilterCondition> {}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const KeepCheckItemSchema = Schema(
  name: r'KeepCheckItem',
  id: -66874220134162345,
  properties: {
    r'isDone': PropertySchema(id: 0, name: r'isDone', type: IsarType.bool),
    r'sortIndex': PropertySchema(
      id: 1,
      name: r'sortIndex',
      type: IsarType.long,
    ),
    r'text': PropertySchema(id: 2, name: r'text', type: IsarType.string),
  },

  estimateSize: _keepCheckItemEstimateSize,
  serialize: _keepCheckItemSerialize,
  deserialize: _keepCheckItemDeserialize,
  deserializeProp: _keepCheckItemDeserializeProp,
);

int _keepCheckItemEstimateSize(
  KeepCheckItem object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.text.length * 3;
  return bytesCount;
}

void _keepCheckItemSerialize(
  KeepCheckItem object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.isDone);
  writer.writeLong(offsets[1], object.sortIndex);
  writer.writeString(offsets[2], object.text);
}

KeepCheckItem _keepCheckItemDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = KeepCheckItem();
  object.isDone = reader.readBool(offsets[0]);
  object.sortIndex = reader.readLong(offsets[1]);
  object.text = reader.readString(offsets[2]);
  return object;
}

P _keepCheckItemDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension KeepCheckItemQueryFilter
    on QueryBuilder<KeepCheckItem, KeepCheckItem, QFilterCondition> {
  QueryBuilder<KeepCheckItem, KeepCheckItem, QAfterFilterCondition>
  isDoneEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isDone', value: value),
      );
    });
  }

  QueryBuilder<KeepCheckItem, KeepCheckItem, QAfterFilterCondition>
  sortIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sortIndex', value: value),
      );
    });
  }

  QueryBuilder<KeepCheckItem, KeepCheckItem, QAfterFilterCondition>
  sortIndexGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sortIndex',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<KeepCheckItem, KeepCheckItem, QAfterFilterCondition>
  sortIndexLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sortIndex',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<KeepCheckItem, KeepCheckItem, QAfterFilterCondition>
  sortIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sortIndex',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<KeepCheckItem, KeepCheckItem, QAfterFilterCondition> textEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepCheckItem, KeepCheckItem, QAfterFilterCondition>
  textGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepCheckItem, KeepCheckItem, QAfterFilterCondition>
  textLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepCheckItem, KeepCheckItem, QAfterFilterCondition> textBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'text',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepCheckItem, KeepCheckItem, QAfterFilterCondition>
  textStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepCheckItem, KeepCheckItem, QAfterFilterCondition>
  textEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepCheckItem, KeepCheckItem, QAfterFilterCondition>
  textContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepCheckItem, KeepCheckItem, QAfterFilterCondition> textMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'text',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<KeepCheckItem, KeepCheckItem, QAfterFilterCondition>
  textIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'text', value: ''),
      );
    });
  }

  QueryBuilder<KeepCheckItem, KeepCheckItem, QAfterFilterCondition>
  textIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'text', value: ''),
      );
    });
  }
}

extension KeepCheckItemQueryObject
    on QueryBuilder<KeepCheckItem, KeepCheckItem, QFilterCondition> {}
