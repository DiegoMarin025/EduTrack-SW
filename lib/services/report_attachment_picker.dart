import 'report_attachment_picker_stub.dart'
    if (dart.library.html) 'report_attachment_picker_web.dart'
    as impl;
import 'report_attachment_picker_types.dart';

export 'report_attachment_picker_types.dart';

Future<SelectedReportAttachment?> pickReportAttachment() {
  return impl.pickReportAttachment();
}
