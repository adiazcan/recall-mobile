import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../openapi/openapi_repository.dart';

class ApiScreen extends ConsumerStatefulWidget {
  const ApiScreen({super.key});

  @override
  ConsumerState<ApiScreen> createState() => _ApiScreenState();
}

class _ApiScreenState extends ConsumerState<ApiScreen> {
  bool _isLoading = false;
  OpenApiDocument? _document;
  String? _error;

  Future<void> _fetchSpec() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = ref.read(openApiRepositoryProvider);
      final document = await repository.fetchSpec();
      setState(() {
        _document = document;
      });
    } on DioException catch (error) {
      final message = error.error?.toString() ?? error.message;
      setState(() {
        _error = 'Failed to fetch OpenAPI spec: $message';
      });
    } catch (error) {
      setState(() {
        _error = 'Failed to fetch OpenAPI spec: $error';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: _isLoading ? null : _fetchSpec,
            child: const Text('Fetch OpenAPI spec'),
          ),
          const SizedBox(height: 16),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          if (_error != null) ...[
            Text(
              _error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (_document != null) ...[
            Text('HTTP status: ${_document!.statusCode}'),
            const SizedBox(height: 4),
            Text('openapi: ${_document!.summary.openapi ?? 'n/a'}'),
            Text('info.title: ${_document!.summary.title ?? 'n/a'}'),
            Text('info.version: ${_document!.summary.version ?? 'n/a'}'),
            const SizedBox(height: 12),
            const Text('Raw JSON'),
            const SizedBox(height: 4),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(_document!.rawJson),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
