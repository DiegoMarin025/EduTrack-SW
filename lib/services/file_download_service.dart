import 'file_download_service_base.dart';
import 'file_download_service_io.dart'
    if (dart.library.html) 'file_download_service_web.dart' as impl;

export 'file_download_service_base.dart';

FileDownloadService createFileDownloadService() =>
    impl.createFileDownloadService();
