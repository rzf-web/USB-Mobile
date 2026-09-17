import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../constant/api_endpoints.dart';
import '../constant/app_color.dart';

/// Widget untuk memuat foto produk dengan mekanisme disk caching lokal.
/// Gambar yang sudah di-download disimpan di storage lokal perangkat
/// sehingga dapat dibuka seketika (0 ms) dan tidak perlu di-download ulang.
class CachedProductImage extends StatefulWidget {
  final String? photoName;
  final Widget Function(BuildContext) fallbackBuilder;
  final BoxFit fit;
  final double? width;
  final double? height;

  const CachedProductImage({
    super.key,
    required this.photoName,
    required this.fallbackBuilder,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
  });

  @override
  State<CachedProductImage> createState() => _CachedProductImageState();
}

class _CachedProductImageState extends State<CachedProductImage> {
  File? _cachedFile;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant CachedProductImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoName != widget.photoName) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    final photo = widget.photoName;
    if (photo == null || photo.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _cachedFile = null;
          _isLoading = false;
          _hasError = false;
        });
      }
      return;
    }

    try {
      final docDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${docDir.path}/product_images');
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }

      final safeName = photo.replaceAll(RegExp(r'[^\w\.\-]'), '_');
      final targetFile = File('${cacheDir.path}/$safeName');

      // Cek apakah file sudah tersimpan di disk lokal
      if (await targetFile.exists() && await targetFile.length() > 0) {
        if (mounted) {
          setState(() {
            _cachedFile = targetFile;
            _isLoading = false;
            _hasError = false;
          });
        }
        return;
      }

      // Download gambar dari backend
      final url = ApiEndpoints.getImageUrl(photo);
      if (url.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final dio = Dio();
      final response = await dio.get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 12),
          sendTimeout: const Duration(seconds: 12),
        ),
      );

      if (response.data != null && response.data!.isNotEmpty) {
        await targetFile.writeAsBytes(response.data!);
        if (mounted) {
          setState(() {
            _cachedFile = targetFile;
            _isLoading = false;
            _hasError = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColor.primary,
          ),
        ),
      );
    }

    if (_hasError || _cachedFile == null) {
      return widget.fallbackBuilder(context);
    }

    return Image.file(
      _cachedFile!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: (_, _, _) => widget.fallbackBuilder(context),
    );
  }
}

