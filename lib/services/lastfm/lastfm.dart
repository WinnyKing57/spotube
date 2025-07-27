import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:spotube/collections/env.dart';

class LastFM {
  final Dio _dio;

=
  static const String _baseUrl = 'https://ws.audioscrobbler.com/2.0/';

  LastFM() : _dio = Dio(BaseOptions(baseUrl: _baseUrl));

  Future<String> getToken() async {
    final params = {
      'method': 'auth.getToken',
      'api_key': Env.lastFmApiKey,
    };
    final signature = _generateApiSignature(params);
    params['api_sig'] = signature;
    params['format'] = 'json';

    final response = await _dio.getUri(
      Uri.parse(_baseUrl).replace(queryParameters: params),
    );

    if (response.statusCode == 200) {
      return response.data['token'];
    } else {
      throw Exception('Failed to get token');
    }
  }

  Future<String> getSession(String token) async {
    final params = {
      'method': 'auth.getSession',
      'api_key': Env.lastFmApiKey,
      'token': token,
    };
    final signature = _generateApiSignature(params);
    params['api_sig'] = signature;
    params['format'] = 'json';

    final response = await _dio.getUri(
      Uri.parse(_baseUrl).replace(queryParameters: params),
    );

    if (response.statusCode == 200) {
      return response.data['session']['key'];
    } else {
      throw Exception('Failed to get session');
    }
  }

  Future<Map<String, dynamic>> getUserInfo(String sessionKey) async {
    final params = {
      'method': 'user.getInfo',
      'api_key': Env.lastFmApiKey,
      'sk': sessionKey,
    };
    final signature = _generateApiSignature(params);
    params['api_sig'] = signature;
    params['format'] = 'json';

    final response = await _dio.getUri(
      Uri.parse(_baseUrl).replace(queryParameters: params),
    );

    if (response.statusCode == 200) {
      return response.data['user'];
    } else {
      throw Exception('Failed to get user info');
    }
  }

  Future<void> scrobble(
    String sessionKey, {
    required String artist,
    required String track,
    required String album,
    required int timestamp,
    int? duration,
    int? trackNumber,
  }) async {
    final params = {
      'method': 'track.scrobble',
      'api_key': Env.lastFmApiKey,
      'sk': sessionKey,
      'artist': artist,
      'track': track,
      'album': album,
      'timestamp': timestamp.toString(),
    };
    if (duration != null) {
      params['duration'] = duration.toString();
    }
    if (trackNumber != null) {
      params['trackNumber'] = trackNumber.toString();
    }

    final signature = _generateApiSignature(params);
    params['api_sig'] = signature;
    params['format'] = 'json';

    await _dio.postUri(
      Uri.parse(_baseUrl),
      data: params,
    );
  }

  Future<void> love(
    String sessionKey, {
    required String artist,
    required String track,
  }) async {
    final params = {
      'method': 'track.love',
      'api_key': Env.lastFmApiKey,
      'sk': sessionKey,
      'artist': artist,
      'track': track,
    };
    final signature = _generateApiSignature(params);
    params['api_sig'] = signature;
    params['format'] = 'json';

    await _dio.postUri(
      Uri.parse(_baseUrl),
      data: params,
    );
  }

  Future<void> unlove(
    String sessionKey, {
    required String artist,
    required String track,
  }) async {
    final params = {
      'method': 'track.unlove',
      'api_key': Env.lastFmApiKey,
      'sk': sessionKey,
      'artist': artist,
      'track': track,
    };
    final signature = _generateApiSignature(params);
    params['api_sig'] = signature;
    params['format'] = 'json';

    await _dio.postUri(
      Uri.parse(_baseUrl),
      data: params,
    );
  }

  String _generateApiSignature(Map<String, String> params) {
    final sortedParams = params.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final paramString =
        sortedParams.map((e) => '${e.key}${e.value}').join('');
    final signature = md5
        .convert(utf8.encode('$paramString${Env.lastFmApiSecret}'))
        .toString();
    return signature;
  }
}
