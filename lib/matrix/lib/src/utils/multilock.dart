/*
 *   Famedly Matrix SDK
 *   Copyright (C) 2019, 2020, 2021 Famedly GmbH
 *
 *   This program is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as
 *   published by the Free Software Foundation, either version 3 of the
 *   License, or (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
import 'dart:async';

/// Lock management class. It allows to lock and unlock multiple keys at once. The keys have
/// the type [T]
class MultiLock<T> {
  final Map<T, Completer<void>> _completers = {};

  /// Set a number of [keys] locks, awaiting them to be released previously.
  Future<void> lock(Iterable<T> keys) async {
    // An iterable might have duplicate entries. A set is guaranteed not to, and we need
    // unique entries, as else a lot of things might go bad.
    final uniqueKeys = keys.toSet();
    // we want to make sure that there are no existing completers for any of the locks
    // we are trying to set. So, we await all the completers until they are all gone.
    // We can't just assume they are all gone after one go, due to rare race conditions
    // which could then result in a deadlock.
    while (_completers.keys.any((k) => uniqueKeys.contains(k))) {
      // Here we try to build all the futures to wait for single completers and then await
      // them at the same time, in parallel
      final futures = <Future<void>>[];
      for (final key in uniqueKeys) {
        if (_completers[key] != null) {
          futures.add(() async {
            while (_completers[key] != null) {
              await _completers[key]!.future;
            }
          }());
        }
      }
      await Future.wait(futures);
    }
    // And finally set all the completers
    for (final key in uniqueKeys) {
      _completers[key] = Completer<void>();
    }
  }

  /// Unlock all [keys] locks. Typically these should be the same keys as called
  /// in `.lock(keys)``
  void unlock(Iterable<T> keys) {
    final uniqueKeys = keys.toSet();
    // we just have to simply unlock all the completers
    for (final key in uniqueKeys) {
      if (_completers[key] != null) {
        final completer = _completers[key]!;
        _completers.remove(key);
        completer.complete();
      }
    }
  }
}
