import 'package:flutter_test/flutter_test.dart';
import 'package:niusic/services/download_service.dart';

void main() {
  test('sanitizeId replaces unsafe characters', () {
    expect(DownloadService.sanitizeId('dQw-4w9WgXcQ'), 'dQw-4w9WgXcQ');
    expect(DownloadService.sanitizeId('a/b\\c:d'), 'a_b_c_d');
    expect(DownloadService.sanitizeId(''), 'download');
  });
}
