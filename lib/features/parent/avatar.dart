/// صورة الطفل — بتتقص مربّع وتتصغّر قبل التخزين، وبتفضل على الجهاز بس ومابتترفعش لأي مكان.
library;

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/theme/app_theme.dart';

/// الصورة الحالية (null = الافتراضية). بتتحمّل مرة في main().
class AvatarController extends Notifier<File?> {
  static const _name = 'child_photo.jpg';

  /// بيتحدد في main() قبل تشغيل التطبيق.
  static File? initial;

  @override
  File? build() => initial;

  static Future<File> _file() async => File('${(await getApplicationDocumentsDirectory()).path}/$_name');

  static Future<File?> load() async {
    final f = await _file();
    return f.existsSync() ? f : null;
  }

  /// يفتح المعرض، يقص مربّع من النص ويصغّره لـ 256 بكسل JPEG.
  Future<String?> pick() async {
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024);
      if (x == null) return 'الصورة اتلغت';
      final bytes = await compute(_shrink, await x.readAsBytes());
      if (bytes == null) return 'الملف ده مش صورة';
      final f = await _file();
      await f.writeAsBytes(bytes, flush: true);
      // نفس المسار — لازم نمسح الكاش عشان الصورة الجديدة تظهر
      imageCache.evict(FileImage(f));
      state = f;
      return null;
    } catch (e) {
      return 'مش قادر أقرا الصورة';
    }
  }

  Future<void> clear() async {
    final f = await _file();
    if (f.existsSync()) await f.delete();
    imageCache.evict(FileImage(f));
    state = null;
  }

  int get sizeKB => state == null || !state!.existsSync() ? 0 : (state!.lengthSync() / 1024).round();
}

Uint8List? _shrink(Uint8List data) {
  final src = img.decodeImage(data);
  if (src == null) return null;
  final s = math.min(src.width, src.height);
  final square = img.copyCrop(src, x: (src.width - s) ~/ 2, y: (src.height - s) ~/ 2, width: s, height: s);
  return img.encodeJpg(img.copyResize(square, width: 256, height: 256), quality: 82);
}

final avatarProvider = NotifierProvider<AvatarController, File?>(AvatarController.new);

/// الصورة الدائرية للطفل.
class ChildAvatar extends ConsumerWidget {
  const ChildAvatar({super.key, this.size = 96});
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(avatarProvider);
    final ImageProvider image = f != null ? FileImage(f) : const AssetImage('assets/images/default_child.jpg');
    // صورة الطفل بإطار دهبي، والافتراضية بإطار أخضر (.avatar.fallback)
    final (ring, shade) = f != null ? (AppColors.gold, AppColors.goldDark) : (AppColors.mint, const Color(0xFF1C8E7F));
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.paper,
        border: Border.all(color: ring, width: 5),
        boxShadow: [BoxShadow(color: shade, offset: const Offset(0, 5))],
        image: DecorationImage(image: image, fit: BoxFit.cover),
      ),
    );
  }
}
