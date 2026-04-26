
import 'package:isar/isar.dart';
import '../../core/helpers/log_helper.dart';
import '../models/bookmark_model.dart';

class BookmarkRepository {
  final Isar _isar;

  BookmarkRepository(this._isar);

  /// Create a new bookmark with success result
  Future<bool> addBookmark(Bookmark bookmark) async {
    try {
      // Normalize URL: trim and auto-prepend protocol if missing
      String normalizedUrl = bookmark.url.trim();
      if (normalizedUrl.isNotEmpty && 
          !normalizedUrl.startsWith('http://') && 
          !normalizedUrl.startsWith('https://')) {
        normalizedUrl = 'https://$normalizedUrl';
      }

      if (normalizedUrl.length > 2048) {
        talker.warning('🔴 Bookmark URL exceeds maximum 2048 safe length bounds.');
        return false;
      }

      final uri = Uri.tryParse(normalizedUrl);
      if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
        talker.warning('🔴 Security: Extracted URL fails HTTP/HTTPS scheme validation: $normalizedUrl');
        return false;
      }

      // Update bookmark with normalized URL before saving
      bookmark.url = normalizedUrl;

      await _isar.writeTxn(() async {
        await _isar.bookmarks.put(bookmark);
      });
      return true;
    } on IsarError catch (e, stack) {
      talker.handle(e, stack, '🔴 Isar Database Error (Add Bookmark)');
      return false;
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Unknown Database Error (Add Bookmark)');
      return false;
    }
  }

  // Read all
  Stream<List<Bookmark>> watchAllBookmarks({int limit = 300}) async* {
    yield* _isar.bookmarks.where().sortByCreatedAtDesc().watch(fireImmediately: true);
  }

  /// Update an existing bookmark with success result
  Future<bool> updateBookmark(Bookmark bookmark) async {
    try {
      // Normalize URL: trim and auto-prepend protocol if missing
      String normalizedUrl = bookmark.url.trim();
      if (normalizedUrl.isNotEmpty && 
          !normalizedUrl.startsWith('http://') && 
          !normalizedUrl.startsWith('https://')) {
        normalizedUrl = 'https://$normalizedUrl';
      }

      if (normalizedUrl.length > 2048) {
        talker.warning('🔴 Bookmark URL exceeds maximum 2048 safe length bounds.');
        return false;
      }

      final uri = Uri.tryParse(normalizedUrl);
      if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
        talker.warning('🔴 Security: Extracted URL fails HTTP/HTTPS scheme validation: $normalizedUrl');
        return false;
      }

      // Update bookmark with normalized URL before saving
      bookmark.url = normalizedUrl;

      await _isar.writeTxn(() async {
        await _isar.bookmarks.put(bookmark);
      });
      return true;
    } on IsarError catch (e, stack) {
      talker.handle(e, stack, '🔴 Isar Database Error (Update Bookmark)');
      return false;
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Unknown Database Error (Update Bookmark)');
      return false;
    }
  }

  /// Delete a bookmark with safety governance
  Future<bool> deleteBookmark(Id id) async {
    try {
      await _isar.writeTxn(() async {
        await _isar.bookmarks.delete(id);
      });
      return true;
    } on IsarError catch (e, stack) {
      talker.handle(e, stack, '🔴 Isar Database Error (Delete Bookmark)');
      return false;
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Unknown Database Error (Delete Bookmark)');
      return false;
    }
  }

  // Search
  Future<List<Bookmark>> searchBookmarks(String query) async {
    return await _isar.bookmarks
        .filter()
        .titleLowerContains(query.toLowerCase())
        .limit(50)
        .findAll();
  }
}
