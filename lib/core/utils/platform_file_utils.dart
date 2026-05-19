import 'dart:io';

bool platformFileExists(String path) => File(path).existsSync();

void platformDeleteFile(String path) {
  final f = File(path);
  if (f.existsSync()) f.deleteSync();
}
