import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'report_attachment_picker_types.dart';

Future<SelectedReportAttachment?> pickReportAttachment() async {
  final completer = Completer<SelectedReportAttachment?>();
  final input = html.FileUploadInputElement()
    ..accept = '.pdf,image/*'
    ..multiple = false;

  late final StreamSubscription<html.Event> changeSub;
  late final StreamSubscription<html.Event> focusSub;
  var cleanedUp = false;

  void cleanup() {
    if (cleanedUp) {
      return;
    }
    cleanedUp = true;
    changeSub.cancel();
    focusSub.cancel();
  }

  changeSub = input.onChange.listen((_) {
    final file = input.files?.isNotEmpty == true ? input.files!.first : null;
    if (file == null) {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
      cleanup();
      return;
    }

    final reader = html.FileReader();
    reader.onLoadEnd.listen((_) {
      final result = reader.result;
      if (result is ByteBuffer) {
        final bytes = Uint8List.view(result);
        if (!completer.isCompleted) {
          completer.complete(
            SelectedReportAttachment(
              fileName: file.name,
              mimeType: file.type.isNotEmpty
                  ? file.type
                  : 'application/octet-stream',
              bytes: bytes,
            ),
          );
        }
      } else {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      }

      cleanup();
    });

    reader.readAsArrayBuffer(file);
  });

  focusSub = html.window.onFocus.listen((_) {
    Future<void>.delayed(const Duration(milliseconds: 250), () {
      if (!completer.isCompleted &&
          (input.files == null || input.files!.isEmpty)) {
        completer.complete(null);
        cleanup();
      }
    });
  });

  input.click();
  return completer.future;
}
