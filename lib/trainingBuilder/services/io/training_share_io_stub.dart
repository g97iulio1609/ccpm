import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';

import '../../../shared/shared.dart';
import '../training_share_service.dart';
import '../training_share_service_async.dart' as async_share;

class TrainingShareIO {
  const TrainingShareIO();

  Future<void> exportProgramFile(
    TrainingProgram program, {
    required String format, // 'json' | 'csv'
    String? suggestedFileName,
  }) async {
    assert(!kIsWeb, 'Use web implementation on web');

    final name = _sanitizeFileName(
      suggestedFileName ?? (program.name.isEmpty ? 'program' : program.name),
    );
    final fileName = '$name.${format.toLowerCase()}';
    final exportMap = TrainingShareService.programToExportMap(program);
    final content = format.toLowerCase() == 'csv'
        ? await async_share.buildCsvAsync(exportMap)
        : await async_share.encodeJsonAsync(exportMap, pretty: false);

    final tempDir = await getTemporaryDirectory();
    final filePath = p.join(tempDir.path, fileName);
    final file = File(filePath);
    await file.writeAsString(content, encoding: utf8);

    await Share.shareXFiles([XFile(filePath)], text: 'Export $fileName');
  }

  Future<TrainingProgram?> importProgramFromFile() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: false,
      withData: true,
      allowedExtensions: const ['json', 'csv'],
    );
    if (res == null || res.files.isEmpty) return null;

    final file = res.files.first;
    final bytes = file.bytes;
    String? path = file.path;
    String content;

    if (bytes != null) {
      content = utf8.decode(bytes);
    } else if (path != null) {
      content = await File(path).readAsString();
    } else {
      return null;
    }

    final ext = (file.extension ?? '').toLowerCase();
    if (ext == 'csv') {
      final map = await async_share.parseCsvToExportMapAsync(content);
      return TrainingShareService.programFromExportMap(
        Map<String, dynamic>.from(map['program'] as Map),
      );
    } else {
      final map = await async_share.parseJsonToExportMapAsync(content);
      return TrainingShareService.programFromExportMap(
        Map<String, dynamic>.from(map['program'] as Map),
      );
    }
  }

  String _sanitizeFileName(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9-_ ]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
  }
}
