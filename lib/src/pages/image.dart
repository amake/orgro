import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
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
