import 'package:flutter/services.dart';
void main() {}
Future<bool> check(String path) async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  return manifest.listAssets().contains(path);
}
