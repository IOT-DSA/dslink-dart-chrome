import "dart:async";
import "dart:convert";
import "dart:js";
import "dart:typed_data";

import "dart:html" hide Document, Window;

import "package:dslink/browser.dart";

import "package:chrome/chrome_ext.dart" as chrome;
import "package:chrome/gen/tts.dart";
import "package:chrome/gen/top_sites.dart";
import "package:chrome/gen/tabs.dart";
import "package:chrome/gen/tab_capture.dart";

import "package:crypto/crypto.dart";
import "package:chrome/chrome_ext.dart" hide LocalMediaStream;

LinkProvider link;

class ChromeLocalStorageDataStore extends DataStorage {
  static final ChromeLocalStorageDataStore INSTANCE = new ChromeLocalStorageDataStore();

  @override
  Future<String> get(String key) async {
    return (await chrome.storage.local.get(key))[key];
  }

  @override
  Future<bool> has(String key) async {
    return (await chrome.storage.local.get())[key];
  }

  @override
  Future<String> remove(String key) async {
    var value = await get(key);
    await chrome.storage.local.remove(key);
    return value;
  }

  @override
  Future store(String key, String value) async {
    await chrome.storage.local.set({
      key: value
    });
  }
}

main() async {
  if (await ChromeLocalStorageDataStore.INSTANCE.has("log_level")) {
    updateLogLevel(await ChromeLocalStorageDataStore.INSTANCE.get("log_level"));
  }

  var brokerUrl = await ChromeLocalStorageDataStore.INSTANCE.get("broker_url");

  if (brokerUrl == null) {
    brokerUrl = "http://127.0.0.1:8080/conn";
  }

  link = new LinkProvider(
    brokerUrl,
    "Chrome-",
    defaultNodes: {
      "openTab": {
        r"$is": "openTab",
        r"$name": "Open Tab",
        r"$invokable": "write",
        r"$result": "values",
        r"$params": [
          {
            "name": "url",
            "type": "string"
          },
          {
            "name": "active",
            "type": "bool",
            "default": true
          }
        ],
        r"$columns": [
          {
            "name": "tab",
            "type": "int"
          }
        ]
      },
      "speak": {
        r"$name": "Speak",
        r"$is": "speak",
        r"$invokable": "write",
        r"$result": "values",
        r"$params": [
          {
            "name": "text",
            "type": "string"
          }
        ],
        r"$columns": []
      },
      "idleState": {
        r"$name": "Idle State",
        r"$type": "enum[active,idle,locked]",
        "?value": "active"
      },
      "mostVisitedSites": {
        r"$name": "Most Visited Sites",
      },
      "tabs": {
        r"$name": "Tabs"
      }
    },
    profiles: {
      "speak": (String path) => new SpeakNode(path),
      "openMostVisitedSite": (String path) => new OpenMostVisitedSiteNode(path),
      "openTab": (String path) => new OpenTabNode(path),
      "eval": (String path) => new EvalNode(path),
      "readMediaStream": (String path) => new MediaCaptureNode(path),
      "takeScreenshot": (String path) => new TakeScreenshotNode(path)
    }
  );

  await link.init();
  await setup();
  await link.connect();
}

Timer timer;

String lastMostVisitedSha;

setup() async {
  timer = new Timer.periodic(const Duration(seconds: 5), (_) async {
    List<MostVisitedURL> topSites = await chrome.topSites.get();

    var datas = [];
    for (var x in topSites) {
      datas.addAll(x.url.codeUnits);
      datas.add("|".codeUnitAt(0));
      datas.addAll(x.title.codeUnits);
      datas.add("|".codeUnitAt(0));
    }

    var s = CryptoUtils.bytesToHex((new SHA1()
      ..add(datas)).close());

    if (lastMostVisitedSha == null || lastMostVisitedSha != s) {
      var c = link["/mostVisitedSites"];
      lastMostVisitedSha = s;
      for (var x in c.children.keys) {
        c.removeChild(x);
      }

      for (var x in topSites) {
        var id = CryptoUtils.bytesToHex((new SHA1()
          ..add(x.url.codeUnits)..add(x.title.codeUnits)).close());

        link.addNode("/mostVisitedSites/${id}", {
          r"$name": x.title,
          "url": {
            r"$name": "URL",
            r"$type": "string",
            "?value": x.url
          },
          "open": {
            r"$name": "Open",
            r"$is": "openMostVisitedSite",
            r"$invokable": "write",
            r"$result": "values",
            r"$params": [],
            r"$columns": [
              {
                "name": "tab",
                "type": "int"
              }
            ]
          }
        });
      }
    }
  });

  chrome.idle.onStateChanged.listen((state) {
    link.updateValue("/idleState", state.toString());
  });

  var addTab = (Tab tab) {
    link.addNode("/tabs/${tab.id}", {
      r"$name": tab.title,
      "title": {
        r"$name": "Title",
        r"$type": "string",
        "?value": tab.title
      },
      "url": {
        r"$name": "URL",
        r"$type": "string",
        "?value": tab.url
      },
      "eval": {
        r"$name": "Evaluate JavaScript",
        r"$invokable": "write",
        r"$is": "eval",
        r"$params": [
          {
            "name": "code",
            "type": "string",
            "editor": "textarea"
          }
        ],
        r"$columns": [
          {
            "name": "result",
            "type": "string"
          }
        ]
      },
      "readAudioStream": {
        r"$name": "Read Audio Stream",
        r"$invokable": "read",
        r"$is": "readMediaStream",
        r"$params": [
        ],
        r"$columns": [
          {
            "name": "data",
            "type": "binary"
          }
        ],
        r"$result": "stream"
      },
      "takeScreenshot": {
        r"$name": "Take Screenshot",
        r"$invokable": "read",
        r"$is": "takeScreenshot",
        r"$params": [
        ],
        r"$columns": [
          {
            "name": "data",
            "type": "string"
          }
        ],
        r"$result": "values"
      }
    });
  };

  chrome.tabs.onCreated.listen(addTab);
  for (Window w in await chrome.windows.getAll()) {
    List<Tab> tabs = await chrome.tabs.getAllInWindow(w.id);
    tabs.forEach(addTab);
  }

  chrome.tabs.onUpdated.listen((OnUpdatedEvent e) {
    SimpleNode node = link["/tabs/${e.tabId}"];
    if (node == null) {
      return;
    }

    if (node.configs[r"$name"] != e.tab.title) {
      node.configs[r"$name"] = e.tab.title;
      node.updateList(r"$name");
    }

    link.val("/tabs/${e.tabId}/title", e.tab.title);
    link.val("/tabs/${e.tabId}/url", e.tab.url);
  });

  chrome.tabs.onRemoved.listen((TabsOnRemovedEvent e) {
    link.removeNode("/tabs/${e.tabId}");
  });

  var state = await chrome.idle.queryState(300);
  link.updateValue("/idleState", state.toString());
}

class SpeakNode extends SimpleNode {
  SpeakNode(String path) : super(path);

  @override
  Object onInvoke(Map<String, dynamic> params) {
    if (params["text"] == null) {
      return {};
    }

    chrome.tts.speak(params["text"], ttsOptions);

    return {};
  }
}

class OpenTabNode extends SimpleNode {
  OpenTabNode(String path) : super(path);

  @override
  onInvoke(Map<String, dynamic> params) async {
    if (params["url"] == null) return {};

    var url = params["url"];
    var active = params["active"];

    Tab tab = await chrome.tabs.create(
      new TabsCreateParams(url: url, active: active));

    return {
      "tab": tab.id
    };
  }
}

class EvalNode extends SimpleNode {
  EvalNode(String path) : super(path);

  @override
  onInvoke(Map<String, dynamic> params) async {
    var p = path.split("/").take(3);
    int tabId = int.parse(p.last);
    String code = params["code"];

    if (code is! String) {
      throw new Exception("Bad Code");
    }

    var details = new InjectDetails(code: code);
    var results = await chrome.tabs.executeScript(details, tabId);
    if (results is List && results.length == 1) {
      results = results.first;
    }

    return {
      "result": JSON.decode(context["JSON"].callMethod("stringify", [results]))
    };
  }
}

class OpenMostVisitedSiteNode extends SimpleNode {
  OpenMostVisitedSiteNode(String path) : super(path);

  @override
  onInvoke(Map<String, dynamic> params) async {
    var p = path.split("/").take(3).join("/");
    var url = link.val("${p}/url");
    var tab = await chrome.tabs.create(
      new TabsCreateParams(url: url, active: true));
    return {
      "tab": tab.id
    };
  }
}

class TakeScreenshotNode extends SimpleNode {
  TakeScreenshotNode(String path) : super(path);

  @override
  onInvoke(Map<String, dynamic> params) async {
    var url = await chrome.tabs.captureVisibleTab();
    return [
      {
        "data": url
      }
    ];
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
        var options = new CaptureOptions(audio: true);
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

      status.stream.onAddTrack.listen((MediaStreamTrackEvent e) {
        MediaStreamTrack track = e.track;
        var reader = new FileReader();
        var blob = new Blob([track]);
        reader.onLoadEnd.listen((ProgressEvent e) {
          controller.add({
            "data": (reader.result as Uint8List).buffer.asByteData()
          });
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

Map<int, TabMediaCaptureStatus> tabCaptures = {};

class TabMediaCaptureStatus {
  int counter = 0;
  MediaStream stream;
}

TtsSpeakParams ttsOptions = new TtsSpeakParams(
  enqueue: true,
  lang: "en-US"
);
