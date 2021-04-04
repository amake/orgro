import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:orgro/src/data_source.dart';
import 'package:orgro/src/navigation.dart';

class RemoteImage extends StatelessWidget {
  const RemoteImage(this.url, {Key? key}) : super(key: key);

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

class LocalImage extends StatelessWidget {
  const LocalImage({
    required this.dataSource,
    required this.relativePath,
    Key? key,
  }) : super(key: key);

  final DataSource dataSource;
  final String relativePath;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => showInteractive(
        context,
        relativePath,
        _futureImage(),
      ),
      child: _futureImage(scale: MediaQuery.of(context).devicePixelRatio),
    );
  }

  Future<Uint8List?> _getBytes() async {
    try {
      final relative = await dataSource.resolveRelative(relativePath);
      return await relative.bytes;
    } on Exception catch (e, s) {
      debugPrint(e.toString());
      debugPrint(s.toString());
      rethrow;
    }
  }

  Widget _futureImage({double scale = 1}) {
    final bytes = _getBytes();
    return FutureBuilder<Uint8List?>(
      future: bytes,
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
