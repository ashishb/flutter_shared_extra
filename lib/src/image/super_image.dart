import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_shared/flutter_shared.dart';
import 'package:flutter_shared_extra/src/image/image_viewer.dart';

class SuperImage extends StatelessWidget {
  const SuperImage(
    this.url, {
    Key key,
    this.width,
    this.fit = BoxFit.cover,
    this.enableViewer = false,
    this.swiperUrls,
  }) : super(key: key);

  final String url;
  final double width;
  final BoxFit fit;
  final bool enableViewer;
  final List<String> swiperUrls;

  Widget extendedImage(
      BuildContext context, String url, double width, BoxFit fit,
      {bool enableViewer = false}) {
    Widget _loadStateChanged(ExtendedImageState state) {
      Widget result;

      switch (state.extendedImageLoadState) {
        case LoadState.loading:
          result = const Center(
            child: CircularProgressIndicator(),
          );
          break;
        case LoadState.failed:
          result = InkWell(
            onTap: () {
              state.reLoadImage();
            },
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Icon(Icons.error, size: 30, color: Colors.red),
                const Positioned(
                  bottom: 10.0,
                  left: 0.0,
                  right: 0.0,
                  child: Text(
                    'Error!\nClick to reload',
                    textScaleFactor: .7,
                    textAlign: TextAlign.center,
                  ),
                )
              ],
            ),
          );
          break;
        case LoadState.completed:
          if (enableViewer) {
            final Widget child = ExtendedRawImage(
              image: state.extendedImageInfo?.image,
            );

            ImageSwiperItem swiperItem;
            int index = 0;
            final List<ImageSwiperItem> swiperItems = [];

            if (swiperUrls != null) {
              for (int i = 0; i < swiperUrls.length; i++) {
                final String u = swiperUrls[i];

                final ImageSwiperItem item = ImageSwiperItem(u);

                if (u == url) {
                  swiperItem = item;
                  index = i;
                }

                swiperItems.add(item);
              }
            } else {
              swiperItem = ImageSwiperItem(url);
              swiperItems.add(swiperItem);
            }

            result = GestureDetector(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (BuildContext context) => ImageViewer(
                    index: index,
                    swiperItems: swiperItems,
                  ),
                ));
              },
              child: Hero(
                tag: swiperItem.heroTag,
                child: child,
              ),
            );
          }

          break;
      }

      return result;
    }

    if (url != null && url.isNotEmpty) {
      if (url.isAssetUrl) {
        return ExtendedImage.asset(
          url,
          width: width,
          fit: fit,
          loadStateChanged: _loadStateChanged,
        );
      }

      return ExtendedImage.network(
        url,
        width: width,
        fit: fit,
        cache: true,
        loadStateChanged: _loadStateChanged,
      );
    }
    return NothingWidget();
  }

  @override
  Widget build(BuildContext context) {
    return extendedImage(context, url, width, fit, enableViewer: enableViewer);
  }
}
