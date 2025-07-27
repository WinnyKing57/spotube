import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotify/spotify.dart';
import 'package:spotube/collections/env.dart';
import 'package:spotube/extensions/artist_simple.dart';
import 'package:spotube/models/database/database.dart';
import 'package:spotube/provider/database/database.dart';
import 'package:spotube/services/lastfm/lastfm.dart';
import 'package:spotube/services/logger/logger.dart';

class ScrobblerNotifier extends AsyncNotifier<LastFM?> {
  final StreamController<Track> _scrobbleController =
      StreamController<Track>.broadcast();
  @override
  build() async {
    final database = ref.watch(databaseProvider);

    final loginInfo = await (database.select(database.scrobblerTable)
          ..where((t) => t.id.equals(0)))
        .getSingleOrNull();

    final subscription =
        database.select(database.scrobblerTable).watch().listen((event) async {
      try {
        if (event.isNotEmpty) {
          state = AsyncValue.data(LastFM());
        } else {
          state = const AsyncValue.data(null);
        }
      } catch (e, stack) {
        AppLogger.reportError(e, stack);
      }
    });

    final scrobblerSubscription =
        _scrobbleController.stream.listen((track) async {
      try {
        final sessionKey = (await database.select(database.scrobblerTable).getSingle()).passwordHash.value;
        await state.asData?.value?.scrobble(
          sessionKey,
          artist: track.artists!.first.name!,
          track: track.name!,
          album: track.album!.name!,
          timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          duration: track.duration?.inSeconds,
          trackNumber: track.trackNumber,
        );
      } catch (e, stackTrace) {
        AppLogger.reportError(e, stackTrace);
      }
    });

    ref.onDispose(() {
      subscription.cancel();
      scrobblerSubscription.cancel();
    });

    if (loginInfo == null) {
      return null;
    }

    return LastFM();
  }

  Future<String> login() async {
    final lastfm = LastFM();
    final token = await lastfm.getToken();
    final url = 'https://www.last.fm/api/auth/?api_key=${Env.lastFmApiKey}&token=$token';
    return url;
  }

  Future<void> getSession(String token) async {
    final lastfm = LastFM();
    final sessionKey = await lastfm.getSession(token);
    final userInfo = await lastfm.getUserInfo(sessionKey);
    final database = ref.read(databaseProvider);
    await database.into(database.scrobblerTable).insert(
          ScrobblerTableCompanion.insert(
            id: const Value(0),
            username: userInfo['name'],
            passwordHash: DecryptedText(sessionKey),
          ),
        );
  }

  Future<void> logout() async {
    state = const AsyncValue.data(null);
    final database = ref.read(databaseProvider);
    await database.delete(database.scrobblerTable).go();
  }

  void scrobble(Track track) {
    _scrobbleController.add(track);
  }

  Future<void> love(Track track) async {
    final database = ref.read(databaseProvider);
    final sessionKey = (await database.select(database.scrobblerTable).getSingle()).passwordHash.value;
    await state.asData?.value?.love(
      sessionKey,
      artist: track.artists!.asString(),
      track: track.name!,
    );
  }

  Future<void> unlove(Track track) async {
    final database = ref.read(databaseProvider);
    final sessionKey = (await database.select(database.scrobblerTable).getSingle()).passwordHash.value;
    await state.asData?.value?.unlove(
      sessionKey,
      artist: track.artists!.asString(),
      track: track.name!,
    );
  }
}

final scrobblerProvider =
    AsyncNotifierProvider<ScrobblerNotifier, LastFM?>(
  () => ScrobblerNotifier(),
);
