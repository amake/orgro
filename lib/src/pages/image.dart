import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:orgro/src/data_source.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/navigation.dart';

class RemoteImage extends StatelessWidget {
  const RemoteImage(this.url, {super.key});

  final String url;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => showInteractive(
        context,
        url,
        Image(image: CachedNetworkImageProvider(url)),
      ),
      child: Image(
        image: CachedNetworkImageProvider(
          url,
          scale: MediaQuery.of(context).devicePixelRatio,
        ),
      ),
    );
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
          return Image.memory(snapshot.data!, scale: scale);
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
