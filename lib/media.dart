library dsa.chrome.media;

import "dart:async";
import "dart:html" as HTML;
import "dart:js";
import "dart:typed_data";

import "package:dslink/dslink.dart";

import "package:chrome/chrome_ext.dart" as chrome;
import "package:chrome/chrome_ext.dart" show
  DesktopCaptureSourceType,
  CaptureOptions;

Map<int, TabMediaCaptureStatus> tabCaptures = {};

class TabMediaCaptureStatus {
  int counter = 0;
  HTML.MediaStream stream;
}

class DesktopCaptureAction extends SimpleNode {
  DesktopCaptureAction(String path) : super(path);

  @override
  onInvoke(Map<String, dynamic> params) async {
    var c = new Completer();
    var id = chrome.desktopCapture.chooseDesktopMedia([
      DesktopCaptureSourceType.SCREEN
    ], (streamId) {
      if (!c.isCompleted) {
        c.complete(streamId);
      }
    });

    new Future.delayed(const Duration(seconds: 5), () {
      if (!c.isCompleted) {
        chrome.desktopCapture.cancelChooseDesktopMedia(id);
        c.complete(null);
      }
    });

    var streamId = await c.future;
    var stream = await HTML.window.navigator.getUserMedia(video: {
      "mandatory": {
        "chromeMediaSource": "desktop",
        "chromeMediaSourceId": streamId
      }
    });

    var controller = new StreamController();

    stream.onAddTrack.listen((HTML.MediaStreamTrackEvent e) {
      HTML.MediaStreamTrack track = e.track;
      var reader = new HTML.FileReader();
      var blob = new HTML.Blob([track]);
      reader.onLoadEnd.listen((HTML.ProgressEvent e) {
        controller.add([[
          (reader.result as Uint8List).buffer.asByteData()
        ]]);
      });
      reader.readAsArrayBuffer(blob);
    });

    return controller.stream;
  }
}

class MediaCaptureNode extends SimpleNode {
  MediaCaptureNode(String path) : super(path);

  @override
  onInvoke(Map<String, dynamic> params) async {
    TabMediaCaptureStatus status;
    var controller = new StreamController();
    try {
      var p = path.split("/").take(3);
      int tabId = int.parse(p.last);
      if (tabCaptures[tabId] is! TabMediaCaptureStatus) {
        status = tabCaptures[tabId] = new TabMediaCaptureStatus();
        var options = new CaptureOptions(video: true);
        var stream = await chrome.tabCapture.capture(options);
        status.stream = stream.jsProxy;
      } else {
        status = tabCaptures[tabId];
      }

      controller.onCancel = () {
        if (status != null) {
          status.counter--;

          if (status.counter <= 0) {
            status.counter = 0;
            status.stream.stop();
            tabCaptures.remove(tabId);
          }
        }
      };

      status.counter++;

      status.stream.onAddTrack.listen((HTML.MediaStreamTrackEvent e) {
        HTML.MediaStreamTrack track = e.track;
        var reader = new HTML.FileReader();
        var blob = new HTML.Blob([track]);
        reader.onLoadEnd.listen((HTML.ProgressEvent e) {
          print(e);
          controller.add([[
            (reader.result as Uint8List).buffer.asByteData()
          ]]);
        });
        reader.readAsArrayBuffer(blob);
      });

      return controller.stream;
    } finally {
      if (status != null) {
        status.counter--;
      }
    }
  }
}
