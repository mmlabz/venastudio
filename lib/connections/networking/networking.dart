import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiProvider {
  final String _baseUrl = 'https://api.marketmindslab.com/vena_studio';

  Uri uri(String url) {
    return Uri.parse(_baseUrl + url);
  }

  // ignore: avoid_positional_boolean_parameters
  Future<dynamic> get(String url, [String? token, bool? print]) async {
    dynamic responseJson;
    try {
      final response = await http.get(
        uri(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      if (print ?? false) debugPrint(response.body);
      responseJson = _response(response);
    } on SocketException {
      throw FetchDataException('No Internet connection');
    }
    return responseJson;
  }

  Future<dynamic> post(
    String url, {
    Object? body,
    String? token,
    bool? print,
  }) async {
    dynamic responseJson;
    try {
      final response = await http.post(
        uri(url),
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
        body: body,
      );
      if (print ?? false) debugPrint(response.body);
      responseJson = _response(response);
    } on SocketException {
      throw FetchDataException('No Internet connection');
    }
    return responseJson;
  }

  Future<dynamic> put(
    String url, {
    required Map<String, dynamic> body,
    String? token,
    bool? print,
  }) async {
    dynamic responseJson;
    try {
      final response = await http.put(
        uri(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
      if (print ?? false) debugPrint(response.body);
      responseJson = _response(response);
    } on SocketException {
      throw FetchDataException('No Internet connection');
    }
    return responseJson;
  }

  Future<dynamic> delete(String url, {String? token, bool? print}) async {
    dynamic responseJson;
    try {
      final response = await http.delete(
        uri(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      if (print ?? false) debugPrint(response.body);
      responseJson = _response(response);
    } on SocketException {
      throw FetchDataException('No Internet connection');
    }
    return responseJson;
  }

  dynamic _response(http.Response response) {
    switch (response.statusCode) {
      case 200:
        try {
          final responseJson = json.decode(response.body);
          return responseJson;
        } catch (err) {
          return response.body;
        }
      case 400:
        throw BadRequestException(response.body);
      case 401:
      case 403:
        throw UnauthorisedException(response.body);
      case 500:
        throw FetchDataException('Internal Server Error');
      default:
        throw FetchDataException(
          '''Error occured while Communication with Server with StatusCode : ${response.statusCode}''',
        );
    }
  }
}

class CustomException implements Exception {
  CustomException([this._message, this._prefix = '']);
  final String? _message;
  final String _prefix;

  @override
  String toString() {
    return '$_prefix$_message';
  }
}

class FetchDataException extends CustomException {
  FetchDataException([String? message])
    : super(message, 'Error During Communication:\n');
}

class BadRequestException extends CustomException {
  BadRequestException([String? message]) : super(message, 'Invalid Request: ');
}

class UnauthorisedException extends CustomException {
  UnauthorisedException([String? message]) : super(message, 'Unauthorised: ');
}

class InvalidInputException extends CustomException {
  InvalidInputException([String? message]) : super(message, 'Invalid Input: ');
}
