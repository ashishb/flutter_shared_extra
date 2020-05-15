import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:random_string/random_string.dart';
import 'package:flutter_shared/flutter_shared.dart';

double initScale({Size imageSize, Size size, double initialScale}) {
  final n1 = imageSize.height / imageSize.width;
  final n2 = size.height / size.width;

  if (n1 > n2) {
    final FittedSizes fittedSizes =
        applyBoxFit(BoxFit.contain, imageSize, size);
    final Size destinationSize = fittedSizes.destination;

    return size.width / destinationSize.width;
  } else if (n1 / n2 < 1 / 4) {
    final FittedSizes fittedSizes =
        applyBoxFit(BoxFit.contain, imageSize, size);
    final Size destinationSize = fittedSizes.destination;

    return size.height / destinationSize.height;
  }

  return initialScale;
}

class ImageViewer extends StatefulWidget {
  const ImageViewer({this.index, this.swiperItems});

  final int index;
  final List<ImageSwiperItem> swiperItems;

  @override
  _ImageSwiperState createState() => _ImageSwiperState();
}

class _ImageSwiperState extends State<ImageViewer>
    with SingleTickerProviderStateMixin {
  StreamController<int> rebuildIndex = StreamController<int>.broadcast();
  StreamController<bool> rebuildSwiper = StreamController<bool>.broadcast();
  AnimationController _animationController;
  Animation<double> _animation;
  void Function() animationListener;
  List<double> doubleTapScales = <double>[1.0, 2.0];
  GlobalKey<ExtendedImageSlidePageState> slidePagekey =
      GlobalKey<ExtendedImageSlidePageState>();
  int currentIndex;
  bool _showSwiper = true;

  @override
  void initState() {
    currentIndex = widget.index;
    _animationController = AnimationController(
        duration: const Duration(milliseconds: 150), vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    rebuildIndex.close();
    rebuildSwiper.close();
    _animationController?.dispose();
    clearGestureDetailsCache();
    super.dispose();
  }

  Widget _itemBuilder(BuildContext context, int index) {
    final size = MediaQuery.of(context).size;

    final url = widget.swiperItems[index].url;
    final String heroTag = widget.swiperItems[index].heroTag;

    final Widget image = ExtendedImage.network(
      url,
      fit: BoxFit.contain,
      enableSlideOutPage: true,
      mode: ExtendedImageMode.gesture,
      heroBuilderForSlidingPage: (Widget result) {
        if (index < min(9, widget.swiperItems.length)) {
          return Hero(
            tag: heroTag,
            child: result,
          );
        } else {
          return result;
        }
      },
      initGestureConfigHandler: (state) {
        double initialScale = 1.0;

        if (state.extendedImageInfo != null &&
            state.extendedImageInfo.image != null) {
          initialScale = initScale(
              size: size,
              initialScale: initialScale,
              imageSize: Size(state.extendedImageInfo.image.width.toDouble(),
                  state.extendedImageInfo.image.height.toDouble()));
        }
        return GestureConfig(
            inPageView: true,
            initialScale: initialScale,
            maxScale: max(initialScale, 5.0),
            animationMaxScale: max(initialScale, 5.0),
            // you can cache gesture state even though page view page change.
            // remember call clearGestureDetailsCache() method at the right time.(for example,this page dispose)
            cacheGesture: false);
      },
      onDoubleTap: (ExtendedImageGestureState state) {
        // you can use define pointerDownPosition as you can,
        // default value is double tap pointer down postion.
        final pointerDownPosition = state.pointerDownPosition;
        final double begin = state.gestureDetails.totalScale;
        double end;

        // remove old
        _animation?.removeListener(animationListener);

        //stop pre
        _animationController.stop();

        //reset to use
        _animationController.reset();

        if (begin == doubleTapScales[0]) {
          end = doubleTapScales[1];
        } else {
          end = doubleTapScales[0];
        }

        animationListener = () {
          // print(_animation.value);
          state.handleDoubleTap(
              scale: _animation.value, doubleTapPosition: pointerDownPosition);
        };
        _animation =
            _animationController.drive(Tween<double>(begin: begin, end: end));

        _animation.addListener(animationListener);

        _animationController.forward();
      },
    );

    // wrap in a gesture detector and add caption
    return GestureDetector(
      onTap: () {
        slidePagekey.currentState.popPage();
        Navigator.pop(context);
      },
      child: image,
    );
  }

  Widget _toolsButton() {
    // snackbar needed a new context
    return Builder(builder: (BuildContext context) {
      return PopupMenuButton<String>(
        icon: Icon(Icons.more_vert),
        onSelected: (String result) {
          switch (result) {
            case 'copy':
              final String url = widget.swiperItems[currentIndex].url;
              Clipboard.setData(ClipboardData(text: url));

              Utils.showSnackbar(context, 'URL copied to clipboard');
              break;
          }
        },
        itemBuilder: (BuildContext context) {
          return [
            const PopupMenuItem<String>(
              value: 'copy',
              child: Text('Copy URL'),
            ),
          ];
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // needed Scaffold for our snackbar
    final Widget imagePage = Scaffold(
      body: Material(
        // if you use ExtendedImageSlidePage and slideType =SlideType.onlyImage,
        // make sure your page is transparent background
        color: Colors.transparent,
        shadowColor: Colors.transparent,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ExtendedImageGesturePageView.builder(
              itemBuilder: _itemBuilder,
              itemCount: widget.swiperItems.length,
              onPageChanged: (int index) {
                currentIndex = index;
                rebuildIndex.add(index);
              },
              controller: PageController(
                initialPage: currentIndex,
              ),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _toolsButton(),
            )
          ],
        ),
      ),
    );

    return ExtendedImageSlidePage(
      key: slidePagekey,
      slideAxis: SlideAxis.both,
      slideType: SlideType.onlyImage,
      onSlidingPage: (state) {
        // you can change other widgets' state on page as you want
        // base on offset/isSliding etc
        // var offset= state.offset;
        final showSwiper = !state.isSliding;
        if (showSwiper != _showSwiper) {
          // do not setState directly here, the image state will change,
          // you should only notify the widgets which are needed to change
          // setState(() {
          // _showSwiper = showSwiper;
          // });

          _showSwiper = showSwiper;
          rebuildSwiper.add(_showSwiper);
        }
      },
      child: imagePage,
    );
  }
}

class ImageSwiperItem {
  ImageSwiperItem(this.url, {this.caption = ''}) : heroTag = randomString(10);

  final String url;
  final String caption;
  final String heroTag;
}
