import 'package:flutter/material.dart';
import 'package:flutter_shared/flutter_shared.dart';
import 'package:flutter_shared_extra/flutter_shared_extra.dart';

class ImageManagerScreen extends StatelessWidget {
  final String appBarTitle = 'Images';

  Widget _buildGrid(BuildContext context, List<ImageUrl> imageUrls) {
    final double width = MediaQuery.of(context).size.width;

    final int count = width ~/ 120;

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: count,
        crossAxisSpacing: 4,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (BuildContext context, int index) {
        return GridTile(
          footer: Text(
            imageUrls[index].name,
            textAlign: TextAlign.center,
          ),
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18.0),
                child: SuperImage(
                  SuperImageSource(url: imageUrls[index].url),
                  enableViewer: true,
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: InkWell(
                  onTap: () async {
                    await showImageDeleteDialog(context, imageUrls[index]);
                  },
                  child: const Icon(Icons.remove_circle,
                      size: 16, color: Color.fromRGBO(200, 0, 0, 1.0)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: Collection<ImageUrl>(path: 'images').streamData(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final List<ImageUrl> imageUrls = snapshot.data as List<ImageUrl>;

            return _buildGrid(context, imageUrls);
          }

          return LoadingWidget();
        },
      ),
      appBar: AppBar(title: Text(appBarTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showImageUploadDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
