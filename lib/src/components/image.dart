import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
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
      return Image(image: CachedNetworkImageProvider(url));
    }
  }

  Widget _scaledImage(BuildContext context, String url) {
    if (_isSvg(url)) {
      return SvgPicture.network(url);
    } else {
      return Image(
        image: CachedNetworkImageProvider(
          url,
          scale: MediaQuery.of(context).devicePixelRatio,
        ),
      );
    }
  }
}

class LocalImage extends StatefulWidget {
  const LocalImage({
    required this.dataSource,
    required this.relativePath,
    super.key,
  });

  final DataSource dataSource;
  final String relativePath;

  @override
  State<LocalImage> createState() => _LocalImageState();
}

class _LocalImageState extends State<LocalImage> {
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
    return GestureDetector(
      onLongPress: () => showInteractive(
        context,
        widget.relativePath,
        _futureImage(),
      ),
      child: _futureImage(scale: MediaQuery.of(context).devicePixelRatio),
    );
  }

  Widget _futureImage({double scale = 1}) {
    return FutureBuilder<Uint8List?>(
      future: _bytes,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return _isSvg(widget.relativePath)
              ? SvgPicture.memory(snapshot.data!)
              : Image.memory(snapshot.data!, scale: scale);
        } else if (snapshot.hasError) {
          return Row(
            children: [
              const Icon(Icons.error),
              const SizedBox(width: 8),
              Flexible(child: Text(snapshot.error.toString()))
            ],
          );
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }
}
