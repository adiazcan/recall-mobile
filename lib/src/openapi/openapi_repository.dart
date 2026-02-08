import 'dart:convert';

import 'package:dio/dio.dart';

import '../config/app_config.dart';

class OpenApiSummary {
  const OpenApiSummary({this.openapi, this.title, this.version});

  final String? openapi;
  final String? title;
  final String? version;
}

class OpenApiDocument {
  const OpenApiDocument({
    required this.statusCode,
    required this.rawJson,
    required this.summary,
  });

  final int statusCode;
  final String rawJson;
  final OpenApiSummary summary;
}

class OpenApiRepository {
  const OpenApiRepository({required Dio client, required AppConfig config})
    : _client = client,
      _config = config;

  final Dio _client;
  final AppConfig _config;

  Future<OpenApiDocument> fetchSpec() async {
    final uri = Uri.parse(_config.openApiSpecUrl);
    final response = await _client.getUri(
      uri,
      options: Options(responseType: ResponseType.plain),
    );

    final statusCode = response.statusCode ?? 0;
    final jsonMap = _tryParseToMap(response.data);

    if (jsonMap == null) {
      return OpenApiDocument(
        statusCode: statusCode,
        rawJson: response.data.toString(),
        summary: const OpenApiSummary(),
      );
    }

    return OpenApiDocument(
      statusCode: statusCode,
      rawJson: const JsonEncoder.withIndent('  ').convert(jsonMap),
      summary: parseOpenApiSummary(jsonMap),
    );
  }
}

OpenApiSummary parseOpenApiSummary(Map<String, dynamic> jsonMap) {
  final info = jsonMap['info'];
  final infoMap = info is Map<String, dynamic> ? info : <String, dynamic>{};

  return OpenApiSummary(
    openapi: jsonMap['openapi']?.toString(),
    title: infoMap['title']?.toString(),
    version: infoMap['version']?.toString(),
  );
}

Map<String, dynamic>? _tryParseToMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is String) {
    final decoded = jsonDecode(value);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
  }

  return null;
}
