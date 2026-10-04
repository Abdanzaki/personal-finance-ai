import 'download_helper_stub.dart'
    if (dart.library.html) 'download_helper_web.dart' as impl;

void downloadFile(String content, String fileName, {String mimeType = 'text/csv'}) {
  impl.downloadFile(content, fileName, mimeType: mimeType);
}
