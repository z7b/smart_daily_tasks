import 'package:flutter/material.dart';

/// Response type determines how the UI renders the message
enum ResponseType {
  text,
  taskCard,
  appointmentCard,
  medicationCard,
  listCard,
  overview,
  error,
}

/// Semantic hint for the controller to enter a follow-up state.
/// Eliminates fragile string-matching for state transitions (H-3).
enum StateHint {
  none,
  awaitingTaskTitle,
  awaitingNoteContent,
  awaitingJournalContent,
  awaitingDeleteTarget,
  awaitingEditTarget,
  guessAddTask,
}

/// A structured response from the assistant
class AssistantResponse {
  final String text;
  final ResponseType type;
  final List<ResponseCard> cards;
  final StateHint stateHint;

  const AssistantResponse({
    required this.text,
    this.type = ResponseType.text,
    this.cards = const [],
    this.stateHint = StateHint.none,
  });

  factory AssistantResponse.text(String text, {StateHint stateHint = StateHint.none}) =>
      AssistantResponse(text: text, stateHint: stateHint);

  factory AssistantResponse.error(String text) =>
      AssistantResponse(text: text, type: ResponseType.error);

  factory AssistantResponse.withCards({
    required String text,
    required ResponseType type,
    required List<ResponseCard> cards,
  }) =>
      AssistantResponse(text: text, type: type, cards: cards);
}

/// A rich card displayed inside a chat bubble
class ResponseCard {
  final String title;
  final String? subtitle;
  final String? timeInfo;
  final String? countdown;
  final String? statusLabel;
  final Color? statusColor;
  final IconData? icon;

  const ResponseCard({
    required this.title,
    this.subtitle,
    this.timeInfo,
    this.countdown,
    this.statusLabel,
    this.statusColor,
    this.icon,
  });
}
