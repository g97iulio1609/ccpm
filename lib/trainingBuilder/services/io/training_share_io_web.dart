import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter,deprecated_member_use
import 'dart:html' as html;

import 'package:file_picker/file_picker.dart';

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
    final name = _sanitizeFileName(
      suggestedFileName ?? (program.name.isEmpty ? 'program' : program.name),
    );
    final fileName = '$name.${format.toLowerCase()}';
    final mime = format.toLowerCase() == 'csv' ? 'text/csv' : 'application/json';
    final exportMap = TrainingShareService.programToExportMap(program);
    final content = format.toLowerCase() == 'csv'
        ? await async_share.buildCsvAsync(exportMap)
        : await async_share.encodeJsonAsync(exportMap, pretty: false);

    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes], mime);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..download = fileName
      ..style.display = 'none';
    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
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
    if (bytes == null) return null;
    final content = utf8.decode(bytes);
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
