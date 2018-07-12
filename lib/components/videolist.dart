import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:simple_moment/simple_moment.dart';
import 'dart:async';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:screen/screen.dart';
import '../flutter_html_view/flutter_html_text.dart';
import 'api.dart';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:share/share.dart';
import 'RateWidget.dart';
import 'dart:io' show Platform;
import 'dart:convert';

const String testDevice = 'YOUR_DEVICE_ID';

int initialShowAd = 3;
int tempShowAd = initialShowAd;

var moment = new Moment.now();

class VideoList extends StatefulWidget {
  @override
  VideoListState createState() => new VideoListState();
}

class VideoListState extends State<VideoList> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return null;
  }
}

Widget buildSubtitles(Future future, context) {
  int jump = 0;
  final Orientation orientation = MediaQuery.of(context).orientation;
  final bool isLandscape = orientation == Orientation.landscape;
  return new FutureBuilder(
    future: future, // a Future<String> or null
    builder: (BuildContext context, AsyncSnapshot snapshot) {
      switch (snapshot.connectionState) {
        case ConnectionState.none:
          return Center(child: new Text('No connection...'));
        case ConnectionState.waiting:
          return Center(child: new CircularProgressIndicator());
        default:
          if (snapshot.hasError)
            return Center(child: new Text('Error: ${snapshot.error}'));
          else
            return new Container(
              color: theme(selectedTheme)["background"],
              child: new GridView.builder(
                  primary: true,
                  gridDelegate: new SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisSpacing: 2.0,
                    crossAxisCount: isLandscape ? 4 : 2,
                    mainAxisSpacing: 5.0,
                  ),
                  padding: const EdgeInsets.all(4.0),
                  itemBuilder: (context, i) {
                    var apiData = snapshot.data;
                    int index = i + jump;
                    if (apiData["result"] != null) {
                      var data = apiData["result"][index];
                      var permlink = data["permlink"];
                      try {
                        var title = data['json_metadata'].split('"title":"')[1].split('",')[0];
                        String description = data['json_metadata'].split(',"description":"')[1].split('",')[0];
                        return _buildRow(data, index, title, description, permlink, context);
                      } catch (e) {
                        try {
                          index++;
                          jump++;
                          data = apiData["result"][index];
                          permlink = data["permlink"];
                          var title = data['json_metadata'].split('"title":"')[1].split('",')[0];
                          String description = data['json_metadata'].split(',"description":"')[1].split('",')[0];
                          return _buildRow(data, index, title, description, permlink, context);
                        } catch (e) {
                          try {
                            index++;
                            jump++;
                            data = apiData["result"][index];
                            permlink = data["permlink"];
                            var title = data['json_metadata'].split('"title":"')[1].split('",')[0];
                            String description = data['json_metadata'].split(',"description":"')[1].split('",')[0];
                            return _buildRow(data, index, title, description, permlink, context);
                          } catch (e) {}
                        }
                      }
                    } else {
                      var data = apiData["results"][index];
                      var permlink = data["permlink"];
                      try {
                        String title = data['meta']['video']['info']['title'];
                        String description = data['meta']['video']['content']['description'];
                        return _buildSearchRow(data, index, title, description, permlink, context);
                      } catch (e) {
                        try {
                          index++;
                          jump++;
                          data = apiData["results"][index];
                          permlink = data["permlink"];
                          String title = data['meta']['video']['info']['title'];
                          String description = data['meta']['video']['content']['description'];
                          return _buildSearchRow(data, index, title, description, permlink, context);
                        } catch (e) {
                          try {
                            index++;
                            jump++;
                            data = apiData["results"][index];
                            permlink = data["permlink"];
                            String title = data['meta']['video']['info']['title'];
                            String description = data['meta']['video']['content']['description'];
                            return _buildSearchRow(data, index, title, description, permlink, context);
                          } catch (e) {}
                        }
                      }
                    }
                    return null;
                  }),
            );
      }
    },
  );
}

Widget _placeholderImage(var imgURL) {
  try {
    return Image.network(
      "https://snap1.d.tube/ipfs/" + imgURL,
      fit: BoxFit.fill,
    );
  } catch (e) {
    return Image.network(
      "https://snap1.d.tube/ipfs/Qma585tFzjmzKemYHmDZoKMZHo8Ar7YMoDAS66LzrM2Lm1",
      fit: BoxFit.scaleDown,
    );
  }
}

Widget _buildRow(var data, var index, var title, var description, var permlink, context) {
  var moment = new Moment.now();
  // handle metadata from (string)json_metadata
  var meta = json.decode(data['json_metadata'].replaceAll(description, "").replaceAll(title, ""));
  return new InkWell(
    child: new Column(
      children: <Widget>[
        _placeholderImage(meta['video']['info']['snaphash']),
        new Text(title, style: new TextStyle(fontSize: 14.0, color: theme(selectedTheme)["text"]), maxLines: 2),
        new Text("by " + data['author'], style: new TextStyle(fontSize: 12.0, color: theme(selectedTheme)["accent"]), maxLines: 1),
        new Text("\$" + data['pending_payout_value'].replaceAll("SBD", "") + " • " + moment.from(DateTime.parse(data['created'])),
            style: new TextStyle(fontSize: 12.0, color: theme(selectedTheme)["accent"]), maxLines: 1),
      ],
    ),
    onTap: () {
      Navigator.push(
        context,
        new MaterialPageRoute(
            builder: (context) => new VideoScreen(
                  permlink: permlink,
                  data: data,
                  description: description,
                  meta: meta,
                  search: false,
                )),
      );
    },
  );
}

Widget _buildSearchRow(var data, var index, var title, var description, var permlink, context) {
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

class VideoScreen extends StatefulWidget {
  final String permlink;
  final data;
  final description;
  final meta;
  final search;
  VideoScreen({
    this.data,
    this.search,
    this.permlink,
    this.description,
    this.meta,
  });
  @override
  VideoScreenState createState() => new VideoScreenState();
}

class VideoScreenState extends State<VideoScreen> {
  var upvoteColor = theme(selectedTheme)["accent"];
  var downvoteColor = theme(selectedTheme)["accent"];
  var subscribed = "Subscribe";
  var gateway = "https://video.dtube.top/ipfs/";
  VideoPlayerController _controller;

  var _ios = Platform.isIOS;
  InterstitialAd myInterstitial;

  @override
  void initState() {
    super.initState();
    getVideo(widget.permlink, widget.data["author"]);
    if (_ios == true) {
      FirebaseAdMob.instance.initialize(appId: "ca-app-pub-9430927632405311~9708042281");
    } else {
      FirebaseAdMob.instance.initialize(appId: "ca-app-pub-9430927632405311~3245387668");
    }
    if (_ios == true) {
      myInterstitial = new InterstitialAd(
        adUnitId: "ca-app-pub-9430927632405311/9921156081",
        listener: (MobileAdEvent event) {
          print("InterstitialAd event is $event");
        },
      );
    } else {
      myInterstitial = new InterstitialAd(
        adUnitId: "ca-app-pub-9430927632405311/4144105868",
        listener: (MobileAdEvent event) {
          print("InterstitialAd event is $event");
        },
      );
    }
    myInterstitial..load();
  }

  double sliderValue;
  var content;
  var result = "loading";
  getVideo(var permlink, var author) async {
    Dio dio = new Dio();
    Response response = await dio.post("https://api.steemit.com", data: {
      "id": 0,
      "jsonrpc": "2.0",
      "method": "call",
      "params": [
        "database_api",
        "get_state",
        ["/dtube/@" + author + "/" + permlink]
      ]
    });
    content = response.data["result"]["content"];
    var _temp = await retrieveData("gateway");
    setState(() {
      result = "loaded";
      gateway = _temp;
    });
    await sVideoController(widget.meta);
  }

  sVideoController(var videoJSON) async {
    var sourcesInit = [
      "480",
      "240",
      "720",
      "1080",
      "",
    ];
    var sources = {};
    int b = 0;
    String _tempVideo;
    for (int i = 0; i < 5; i++) {
      _tempVideo = videoJSON["video"]["content"]["video${sourcesInit[i]}hash"];
      if (_tempVideo != null) {
        sources[b] = gateway + _tempVideo;
        b++;
      }
      if (i == 4) {
        setState(() {
          _controller = VideoPlayerController.network(sources[0]);
        });
      }
    }
  }

  setSlider(e) {
    setState(() {
      sliderValue = e;
    });
  }

  //getVideo(permlink);
  @override
  Widget build(BuildContext contextWidget) {
    Screen.keepOn(true);
    return new WillPopScope(
      onWillPop: _onWillPop,
      child: new Scaffold(
        appBar: new AppBar(
          backgroundColor: theme(selectedTheme)["background"],
          title: new Text(widget.data["title"], style: new TextStyle(color: theme(selectedTheme)["accent"])),
          actions: <Widget>[
            new FlatButton(
              onPressed: () {
                print(widget.data["url"]);
                Share.share("https://d.tube/v/" + widget.data["author"] + "/" + widget.data["permlink"]);
              },
              child: new Icon(Icons.share, color: theme(selectedTheme)["accent"]),
            ),
          ],
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
                onPressed: () async {
                  try {
                    _controller.pause();
                  } catch (e) {
                    try {
                      _controller.dispose();
                    } catch (e) {}
                  }
                  tempShowAd--;
                  if (tempShowAd == 0 && await retrieveData("no_ads") == null) {
                    myInterstitial
                      ..load()
                      ..show().then((e) {
                        myInterstitial..load();
                      });
                    tempShowAd = initialShowAd;
                  }
                  Navigator.pop(contextWidget);
                },
              ),
            ],
          ),
        ),
        body: new Center(
          child: new Column(
            children: <Widget>[
              new Container(
                child: result == "loading"
                    ? Center(child: new CircularProgressIndicator())
                    : new Expanded(
                        child: ListView.builder(
                        itemCount: 10,
                        itemBuilder: (contextListViewBuilder, index) {
                          if (index == 0)
                            return new Column(
                              children: <Widget>[
                                _controller != null
                                    ? new Chewie(
                                        _controller,
                                        aspectRatio: 16 / 9,
                                        autoPlay: true,
                                        looping: false,
                                      )
                                    : new CircularProgressIndicator(),
                                new Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: new Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      new Row(
                                        children: <Widget>[
                                          new Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: new CircleAvatar(
                                              radius: 35.0,
                                              backgroundImage:
                                                  new NetworkImage("https://steemitimages.com/u/" + widget.data["author"] + "/avatar/big"),
                                            ),
                                          ),
                                          new Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: <Widget>[
                                              new Padding(
                                                padding: const EdgeInsets.all(10.0),
                                                child: new Text(widget.data["author"]),
                                              ),
                                              new RaisedButton(
                                                color: theme(selectedTheme)["primary"],
                                                onPressed: () async {
                                                  await broadcastSubscribe(contextListViewBuilder, widget.data["author"]);
                                                  setState(() {
                                                    subscribed = "Subscribed";
                                                  });
                                                },
                                                child: Column(
                                                  children: <Widget>[
                                                    new Text(subscribed, style: new TextStyle(color: Colors.white)),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      new Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: <Widget>[
                                          new IconButton(
                                              icon: const Icon(FontAwesomeIcons.thumbsUp),
                                              color: upvoteColor,
                                              onPressed: () {
                                                setState(() {
                                                  upvoteColor = theme(selectedTheme)["primary"];
                                                });
                                                return showDialog(
                                                  context: contextListViewBuilder,
                                                  barrierDismissible: false, // user must tap button!
                                                  builder: (BuildContext contextDialog) {
                                                    return new StatefulBuilder(builder: (BuildContext contextStatefulBuilder, setState) {
                                                      return new AlertDialog(
                                                        title: new Text('Select Upvoting power'),
                                                        content: new SingleChildScrollView(
                                                          child: new ListBody(
                                                            children: <Widget>[
                                                              new Padding(
                                                                padding: const EdgeInsets.only(top: 50.0, left: 10.0, right: 10.0),
                                                                child: new Slider(
                                                                  onChanged: (e) {
                                                                    setState(() {
                                                                      sliderValue = e;
                                                                    });
                                                                  },
                                                                  value: sliderValue != null ? sliderValue : 10.0,
                                                                  min: 10.0,
                                                                  max: 100.0,
                                                                  divisions: 9,
                                                                  label: sliderValue.toString(),
                                                                ),
                                                              )
                                                            ],
                                                          ),
                                                        ),
                                                        actions: <Widget>[
                                                          new FlatButton(
                                                            child: new Text('CLOSE'),
                                                            onPressed: () {
                                                              Navigator.of(contextStatefulBuilder, rootNavigator: true).pop(result);
                                                            },
                                                          ),
                                                          new FlatButton(
                                                            child: new Text('UPVOTE'),
                                                            onPressed: () {
                                                              Navigator.of(contextStatefulBuilder, rootNavigator: true).pop(result);
                                                              broadcastVote(
                                                                  contextStatefulBuilder, widget.data["author"], widget.permlink, toInt(sliderValue));
                                                            },
                                                          ),
                                                        ],
                                                      );
                                                    });
                                                  },
                                                );
                                              }),
                                          new IconButton(
                                              icon: const Icon(FontAwesomeIcons.thumbsDown),
                                              color: downvoteColor,
                                              onPressed: () {
                                                setState(() {
                                                  downvoteColor = theme(selectedTheme)["primary"];
                                                });
                                                return showDialog(
                                                  context: contextListViewBuilder,
                                                  barrierDismissible: false, // user must tap button!
                                                  builder: (BuildContext contextDialog) {
                                                    return new StatefulBuilder(builder: (BuildContext contextStatefulBuilder, setState) {
                                                      return new AlertDialog(
                                                        title: new Text('Select Downvoting power'),
                                                        content: new SingleChildScrollView(
                                                          child: new ListBody(
                                                            children: <Widget>[
                                                              new Padding(
                                                                padding: const EdgeInsets.only(top: 50.0, left: 10.0, right: 10.0),
                                                                child: new Slider(
                                                                  onChanged: (e) {
                                                                    setState(() {
                                                                      sliderValue = e;
                                                                    });
                                                                  },
                                                                  value: sliderValue != null ? sliderValue : 10.0,
                                                                  min: 10.0,
                                                                  max: 100.0,
                                                                  divisions: 9,
                                                                  label: sliderValue.toString(),
                                                                ),
                                                              )
                                                            ],
                                                          ),
                                                        ),
                                                        actions: <Widget>[
                                                          new FlatButton(
                                                            child: new Text('CLOSE'),
                                                            onPressed: () {
                                                              Navigator.of(contextStatefulBuilder, rootNavigator: true).pop(result);
                                                            },
                                                          ),
                                                          new FlatButton(
                                                            child: new Text('DOWNVOTE'),
                                                            onPressed: () async {
                                                              Navigator.of(contextStatefulBuilder, rootNavigator: true).pop(result);
                                                              await broadcastVote(
                                                                  contextListViewBuilder, widget.data["author"], widget.permlink, toInt(sliderValue));
                                                            },
                                                          ),
                                                        ],
                                                      );
                                                    });
                                                  },
                                                );
                                              }),
                                          new Text(
                                            "\$" +
                                                (widget.search ? widget.data["payout"] : widget.data["pending_payout_value"])
                                                    .toString()
                                                    .replaceFirst(" SBD", ""),
                                            style: new TextStyle(fontSize: 15.0),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                new Divider(
                                  height: 1.0,
                                  color: theme(selectedTheme)["accent"],
                                  indent: 0.0,
                                ),
                                RateWidget(),
                                new Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: new Column(
                                      children: <Widget>[
                                        Card(
                                          color: Colors.lightGreen,
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: new Text(
                                              "added " + moment.from(DateTime.parse(widget.data["created"])),
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                        new HtmlText(data: linkify(widget.description)),
                                        new Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: new TextField(
                                            decoration: new InputDecoration(hintText: 'Comment something...'),
                                            onSubmitted: (comment) {
                                              broadcastComment(contextListViewBuilder, widget.data["author"], widget.permlink, comment.toString());
                                            },
                                          ),
                                        ),
                                      ],
                                    )),
                                new Divider(),
                                // TODO: comments class
                              ],
                            );
                          else if (index > 0) {
                            try {
                              var reply = content[content[widget.data["author"] + "/" + widget.permlink]["replies"][index - 1].toString()];
                              var comment = linkify(reply["body"]);
                              if ((reply["body"].toString()).length > 100) {
                                comment = linkify(reply["body"].substring(0, 100)).toString() + "...";
                              }
                              return new Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: new ExpansionTile(
                                  title: new Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      new Row(
                                        children: <Widget>[
                                          new CircleAvatar(
                                            radius: 13.0,
                                            backgroundImage: new NetworkImage("https://steemitimages.com/u/" + reply["author"] + "/avatar/small"),
                                          ),
                                          new Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: new Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: <Widget>[
                                                new Text(
                                                  reply["author"],
                                                  style: TextStyle(fontSize: 14.0),
                                                ),
                                                new Row(
                                                  children: <Widget>[
                                                    new Text(
                                                      moment.from(DateTime.parse(reply["created"])),
                                                      style: TextStyle(color: theme(selectedTheme)["accent"], fontSize: 12.0),
                                                    ),
                                                    new Padding(
                                                      padding: const EdgeInsets.only(left: 4.0),
                                                      child: new Text("\$" + reply["pending_payout_value"].toString().replaceFirst("SBD", ""),
                                                          style: TextStyle(color: theme(selectedTheme)["accent"], fontSize: 12.0)),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      new Text(
                                        comment,
                                        style: TextStyle(fontSize: 14.0),
                                      ),
                                    ],
                                  ),
                                  children: <Widget>[
                                    new Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: (reply["body"].toString()).length > 100 ? new HtmlText(data: linkify(reply["body"])) : new Container(),
                                    ),
                                    new Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: <Widget>[
                                        new Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: new Icon(
                                            FontAwesomeIcons.thumbsUp,
                                            color: theme(selectedTheme)["accent"],
                                          ),
                                        ),
                                        new Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: new Icon(
                                            FontAwesomeIcons.thumbsDown,
                                            color: theme(selectedTheme)["accent"],
                                          ),
                                        ),
                                      ],
                                    ),
                                    new Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: new TextField(
                                        decoration: new InputDecoration(hintText: 'Comment something...'),
                                        onSubmitted: (comment) {
                                          broadcastComment(contextListViewBuilder, reply["author"], reply["permlink"], comment);
                                        },
                                      ),
                                    )
                                  ],
                                ),
                              );
                            } catch (e) {}
                          }
                        },
                      )),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    try {
      _controller.pause();
    } catch (e) {
      try {
        _controller.dispose();
      } catch (e) {}
    }
    tempShowAd--;
    if (tempShowAd == 0 && await retrieveData("no_ads") == null) {
      myInterstitial
        ..load()
        ..show().then((e) {
          myInterstitial..load();
        });
      tempShowAd = initialShowAd;
    }
    Navigator.of(context).pop(true);
  }
  /*

        print("popped");
        try {
          _controller.pause();
        } catch (e) {
          try {
            _controller.dispose();
          } catch (e) {}
          ;
        }
        Navigator.pop(contextWidget);
        tempShowAd--;
        if (tempShowAd == 0 && await retrieveData("no_ads") == null) {
          myInterstitial
            ..load()
            ..show().then((e) {
              myInterstitial..load();
            });
          tempShowAd = initialShowAd;
        }
   */
}
