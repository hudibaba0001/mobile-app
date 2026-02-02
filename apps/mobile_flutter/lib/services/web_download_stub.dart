// Stub implementation for non-web platforms
import 'dart:typed_data';

void downloadFileWeb(Uint8List bytes, String fileName, String mimeType) {
  // No-op on non-web platforms
  // This method should never be called on non-web platforms
  // due to kIsWeb check in ExportService
}

