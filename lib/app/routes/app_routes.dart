// ignore_for_file: constant_identifier_names

abstract class Routes {
  Routes._();
  static const HOME = _Paths.HOME;
  static const TASKS = _Paths.TASKS;
  static const ADD_TASK = _Paths.ADD_TASK;
  static const NOTES = _Paths.NOTES;
  static const ADD_NOTE = _Paths.ADD_NOTE;
  static const JOURNAL = _Paths.JOURNAL;
  static const ADD_JOURNAL = _Paths.ADD_JOURNAL;
  static const BOOKMARKS = _Paths.BOOKMARKS;
  static const ADD_BOOKMARK = _Paths.ADD_BOOKMARK;
  static const CALENDAR = _Paths.CALENDAR;
  static const ASSISTANT = _Paths.ASSISTANT;
  static const SETTINGS = _Paths.SETTINGS;
  static const BOOKS = _Paths.BOOKS;
  static const MEDICATION = _Paths.MEDICATION;
  static const STEPS = _Paths.STEPS;
  static const JOB = _Paths.JOB;
  static const JOB_SETTINGS = _Paths.JOB_SETTINGS;
}

abstract class _Paths {
  _Paths._();
  static const HOME = '/home';
  static const TASKS = '/tasks';
  static const ADD_TASK = '/add-task';
  static const NOTES = '/notes';
  static const ADD_NOTE = '/add-note';
  static const JOURNAL = '/journal';
  static const ADD_JOURNAL = '/add-journal';
  static const BOOKMARKS = '/bookmarks';
  static const ADD_BOOKMARK = '/add-bookmark';
  static const CALENDAR = '/calendar';
  static const ASSISTANT = '/assistant';
  static const SETTINGS = '/settings';
  static const BOOKS = '/books';
  static const MEDICATION = '/medication';
  static const STEPS = '/steps';
  static const JOB = '/job';
  static const JOB_SETTINGS = '/job-settings';
}
