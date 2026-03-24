import 'dart:typed_data';

class SelectedReportAttachment {
  final String fileName;
  final String mimeType;
  final Uint8List bytes;

  const SelectedReportAttachment({
    required this.fileName,
    required this.mimeType,
    required this.bytes,
  });

  int get sizeBytes => bytes.lengthInBytes;
}
