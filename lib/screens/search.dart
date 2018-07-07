import 'package:flutter/material.dart';
import 'package:simple_moment/simple_moment.dart';
import '../components/api.dart';
import '../components/videolist.dart';

class SearchScreen extends StatefulWidget {
  final String search;
  SearchScreen({
    this.search,
  });
  @override
  SearchScreenState createState() => new SearchScreenState();
}

class SearchScreenState extends State<SearchScreen> {
  var content;
  var result = "loading";
  var apiData3;

  _getVideos() async {
    apiData3 = await steemit.getDiscussionsBySearch(widget.search);
    setState(() {
      apiData3 = apiData3;
    });
  }

  @override
  void initState() {
    _getVideos();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        backgroundColor: theme(selectedTheme)["background"],
        title: new Text(widget.search),
        automaticallyImplyLeading: false,
        leading: new Row(
          textDirection: TextDirection.ltr,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            new IconButton(
              icon: new Icon(
                Icons.arrow_back,
                color: theme(selectedTheme)["accent"],
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: new Center(child: apiData3 != null ? _buildSubtitles() : new CircularProgressIndicator()),
    );
  }

  Widget _buildSubtitles() {
    final Orientation orientation = MediaQuery.of(context).orientation;
    final bool isLandscape = orientation == Orientation.landscape;
    int jump = 0;

    return new RefreshIndicator(
        onRefresh: () {
          print("test");
        },
        child: new Center(
          child: new GridView.builder(
              primary: true,
              gridDelegate: new SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisSpacing: 2.0,
                crossAxisCount: isLandscape ? 4 : 2,
                mainAxisSpacing: 5.0,
              ),
              itemCount: 100, // TODO: add _subtitles.length after update
              padding: const EdgeInsets.all(4.0),
              itemBuilder: (context, i) {
                int index = i + jump;
                var data = apiData3["result"][index];
                var permlink = data["permlink"];
                print(index);
                try {
                  var title = data['json_metadata'].split('"title":"')[1].split('",')[0];
                  String description = data['json_metadata'].split(',"description":"')[1].split('",')[0];
                  return _buildRow(data, index, title, description, permlink);
                } catch (e) {
                  try {
                    index++;
                    jump++;
                    data = apiData3["result"][index];
                    permlink = data["permlink"];
                    var title = data['json_metadata'].split('"title":"')[1].split('",')[0];
                    String description = data['json_metadata'].split(',"description":"')[1].split('",')[0];
                    return _buildRow(data, index, title, description, permlink);
                  } catch (e) {
                    try {
                      index++;
                      jump++;
                      data = apiData3["result"][index];
                      permlink = data["permlink"];
                      var title = data['json_metadata'].split('"title":"')[1].split('",')[0];
                      String description = data['json_metadata'].split(',"description":"')[1].split('",')[0];
                      return _buildRow(data, index, title, description, permlink);
                    } catch (e) {}
                  }
                }
                return null;
              }),
        ));
  }

  Widget _placeholderImage(var imgURL) {
    try {
      return Image.network(
        "https://ipfs.io/ipfs/" + imgURL,
        fit: BoxFit.scaleDown,
      );
    } catch (e) {
      return Image.network(
        "https://ipfs.io/ipfs/Qma585tFzjmzKemYHmDZoKMZHo8Ar7YMoDAS66LzrM2Lm1",
        fit: BoxFit.scaleDown,
      );
    }
  }

  Widget _buildRow(var data, var index, var title, var description, var permlink) {
    var moment = new Moment.now();
    // handle metadata from (string)json_metadata
    var meta = data['meta'];
    return new InkWell(
      child: new Column(
        children: <Widget>[
          _placeholderImage(meta['video']['info']['snaphash']),
          new Text(title, style: new TextStyle(fontSize: 14.0), maxLines: 2),
          new Text("by " + data['author'], style: new TextStyle(fontSize: 12.0, color: theme(selectedTheme)["accent"]), maxLines: 1),
          new Text("\$" + data['payout'].toString() + " • " + moment.from(DateTime.parse(data['created'])),
              style: new TextStyle(fontSize: 12.0, color: theme(selectedTheme)["accent"]), maxLines: 1),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          new MaterialPageRoute(
              builder: (context) => new VideoScreen(permlink: permlink, data: data, description: description, meta: meta, search: true)),
        );
      },
    );
  }
}
