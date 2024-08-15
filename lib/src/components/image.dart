import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:orgro/src/data_source.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/navigation.dart';

bool _isSvg(String url) {
  final segments = Uri.parse(url).pathSegments;
  return segments.isEmpty ? false : segments.last.endsWith('.svg');
}

class RemoteImage extends StatelessWidget {
  const RemoteImage(this.url, {super.key});

  final String url;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => showInteractive(context, url, _image(context, url)),
      child: _scaledImage(context, url),
    );
  }

  Widget _image(BuildContext context, String url) {
    if (_isSvg(url)) {
      return SvgPicture.network(url);
    } else {
      return CachedNetworkImage(imageUrl: url);
    }
  }

  Widget _scaledImage(BuildContext context, String url) {
    if (_isSvg(url)) {
      return SvgPicture.network(url);
    } else {
      return CachedNetworkImage(
        imageUrl: url,
        scale: MediaQuery.of(context).devicePixelRatio,
      );
    }
  }
}

class LocalImage extends StatelessWidget {
  const LocalImage({
    required this.dataSource,
    required this.relativePath,
    super.key,
  });

  final DataSource dataSource;
  final String relativePath;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => showInteractive(context, relativePath, _image()),
      child: _image(minimizeSize: true),
    );
  }

  Widget _image({bool minimizeSize = false}) => _isSvg(relativePath)
      ? _LocalSvgImage(dataSource: dataSource, relativePath: relativePath)
      : _LocalOtherImage(
          dataSource: dataSource,
          relativePath: relativePath,
          minimizeSize: minimizeSize,
        );
}

class _LocalOtherImage extends StatelessWidget {
  const _LocalOtherImage({
    required this.dataSource,
    required this.relativePath,
    required this.minimizeSize,
  });

  final DataSource dataSource;
  final String relativePath;
  final bool minimizeSize;

  @override
  Widget build(BuildContext context) {
    if (!minimizeSize) {
      return Image(
        image: _DataSourceImage(dataSource, relativePath),
        errorBuilder: (context, error, stackTrace) =>
            _ImageError(error.toString()),
        loadingBuilder: (context, child, loadingProgress) =>
            loadingProgress == null ? child : const CircularProgressIndicator(),
      );
    }
    return LayoutBuilder(builder: (context, constraints) {
      final scale = MediaQuery.of(context).devicePixelRatio;
      return Image(
        image: ResizeImage.resizeIfNeeded(
            constraints.hasBoundedWidth
                ? (constraints.maxWidth * scale).toInt()
                : null,
            constraints.hasBoundedHeight
                ? (constraints.maxHeight * scale).toInt()
                : null,
            _DataSourceImage(
              dataSource,
              relativePath,
              scale: scale,
            )),
        errorBuilder: (context, error, stackTrace) =>
            _ImageError(error.toString()),
        loadingBuilder: (context, child, loadingProgress) =>
            loadingProgress == null ? child : const CircularProgressIndicator(),
      );
    });
  }
}

class _LocalSvgImage extends StatefulWidget {
  _LocalSvgImage({
    required this.dataSource,
    required this.relativePath,
  }) : assert(_isSvg(relativePath));

  final DataSource dataSource;
  final String relativePath;

  @override
  State<_LocalSvgImage> createState() => _LocalSvgImageState();
}

class _LocalSvgImageState extends State<_LocalSvgImage> {
  late Future<Uint8List?> _bytes;

  @override
  void initState() {
    super.initState();
    _bytes = _getBytes();
  }

  Future<Uint8List?> _getBytes() async {
    try {
      final relative =
          await widget.dataSource.resolveRelative(widget.relativePath);
      return await relative.bytes;
    } on Exception catch (e, s) {
      logError(e, s);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _bytes,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return SvgPicture.memory(snapshot.data!);
        } else if (snapshot.hasError) {
          return _ImageError(snapshot.error.toString());
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }
}

class _ImageError extends StatelessWidget {
  const _ImageError(this.error);

  final String error;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.error),
        const SizedBox(width: 8),
        Flexible(child: Text(error))
      ],
    );
  }
}

// Copied largely from FileImage
class _DataSourceImage extends ImageProvider<_DataSourceImage> {
  const _DataSourceImage(this.dataSource, this.relativePath, {this.scale = 1});

  final DataSource dataSource;
  final String relativePath;
  final double scale;

  @override
  Future<_DataSourceImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<_DataSourceImage>(this);
  }

  @override
  @protected
  ImageStreamCompleter loadImage(
      _DataSourceImage key, ImageDecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode: decode),
      scale: key.scale,
      debugLabel: key.dataSource.id,
      informationCollector: () => <DiagnosticsNode>[
        ErrorDescription('Path: ${key.dataSource.id} / $relativePath'),
      ],
    );
  }

  Future<ui.Codec> _loadAsync(
    _DataSourceImage key, {
    required ImageDecoderCallback decode,
  }) async {
    assert(key == this);

    final relative = await key.dataSource.resolveRelative(key.relativePath);
    final bytes = await relative.bytes;
    if (bytes.isEmpty) {
      // The file may become available later.
      PaintingBinding.instance.imageCache.evict(key);
      throw StateError(
          '${key.dataSource.id} / $relativePath is empty and cannot be loaded as an image.');
    }
    return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is _DataSourceImage &&
        other.dataSource.id == dataSource.id &&
        other.relativePath == relativePath &&
        other.scale == scale;
  }

  @override
  int get hashCode => Object.hash(dataSource.id, relativePath, scale);

  @override
  String toString() =>
      '${objectRuntimeType(this, '_DataSourceImage')}("${dataSource.id} / $relativePath", scale: ${scale.toStringAsFixed(1)})';
}
