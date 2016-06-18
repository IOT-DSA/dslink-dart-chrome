import "dart:async";
import "dart:convert";
import "dart:js";
import "dart:typed_data";

import "dart:html" hide Document, Window;

import "package:dslink/browser.dart";
import "package:dslink/utils.dart";

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
    return (await chrome.storage.sync.get(key))[key];
  }

  @override
  Future<bool> has(String key) async {
    return (await chrome.storage.sync.get())[key];
  }

  @override
  Future<String> remove(String key) async {
    var value = await get(key);
    await chrome.storage.sync.remove(key);
    return value;
  }

  @override
  Future store(String key, String value) async {
    await chrome.storage.sync.set({
      key: value
    });
  }
}

List<Function> _dones = [];

onDone(Function e) {
  _dones.add(e);
}

done() {
  while (_dones.isNotEmpty) {
    _dones.removeAt(0)();
  }
}

main() async {
  onDone(chrome.storage.onChanged.listen((e) {
    if (e.areaName == "sync") {
      if (const [
        "broker_url",
        "link_name",
        "log_level"
      ].any((x) => e.changes.containsKey(x))) {
        reload();
      }
    }
  }).cancel);

  onDone(chrome.extension.onRequest.listen((chrome.OnRequestEvent e) {
    print("Received Request: ${e.request}");

    if (e.request == "reload") {
      reload();
    }

    if (e.sendResponse != null) {
      e.sendResponse();
    }
  }).cancel);

  var store = await chrome.storage.sync.get();
  var replace = {};

  if (store["broker_url"] is! String) {
    replace["broker_url"] = "http://127.0.0.1:8080/conn";
  }

  if (store["log_level"] is! String) {
    replace["log_level"] = "INFO";
  }

  if (store["link_name"] is! String) {
    replace["link_name"] = "Chrome";
  }

  if (replace.isNotEmpty) {
    await chrome.storage.sync.set(replace);
  }

  updateLogLevel(await ChromeLocalStorageDataStore.INSTANCE.get("log_level"));
  var brokerUrl = await ChromeLocalStorageDataStore.INSTANCE.get("broker_url");
  var linkName = await ChromeLocalStorageDataStore.INSTANCE.get("link_name");

  if (!linkName.endsWith("-")) {
    linkName += "-";
  }

  link = new LinkProvider(
    brokerUrl,
    linkName,
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
        r"$result": "stream",
        r"$params": [
          {
            "name": "text",
            "type": "string"
          },
          {
            "name": "lang",
            "type": "string",
            "default": "en-US"
          },
          {
            "name": "rate",
            "type": "number",
            "default": 1.0
          },
          {
            "name": "pitch",
            "type": "number",
            "default": 1.0
          },
          {
            "name": "gender",
            "type": "enum[male,female]",
            "default": "female"
          },
          {
            "name": "volume",
            "type": "number",
            "default": 1.0
          },
          {
            "name": "voiceName",
            "type": "string",
            "default": ""
          },
          {
            "name": "enqueue",
            "type": "bool",
            "default": true
          }
        ],
        r"$columns": [
          {
            "name": "lastEvent",
            "type": "map"
          }
        ]
      },
      "cancelSpeech": {
        r"$name": "Cancel Speech",
        r"$invokable": "write",
        r"$result": "values",
        r"$is": "cancelSpeech",
        r"$columns": [],
        r"$params": []
      },
      "createNotification": {
        r"$name": "Create Notification",
        r"$invokable": "write",
        r"$is": "createNotification",
        r"$params": [
          {
            "name": "title",
            "type": "string",
            "placeholder": "Hello World"
          },
          {
            "name": "message",
            "type": "string",
            "placeholder": "How are you today?"
          },
          {
            "name": "iconUrl",
            "type": "string",
            "placeholder": "http://pandas.are.awesome/panda.png"
          },
          {
            "name": "contextMessage",
            "type": "string",
            "placeholder": "Pandas are awesome."
          },
          {
            "name": "requireInteraction",
            "type": "bool",
            "value": false
          }
        ],
        r"$result": "values",
        r"$columns": [
          {
            "name": "notificationId",
            "type": "string"
          }
        ]
      },
      "updateNotification": {
        r"$name": "Update Notification",
        r"$invokable": "write",
        r"$is": "updateNotification",
        r"$params": [
          {
            "name": "notificationId",
            "type": "string",
            "placeholder": "123e4567-e89b-12d3-a456-426655440000"
          },
          {
            "name": "title",
            "type": "string",
            "placeholder": "Hello World"
          },
          {
            "name": "message",
            "type": "string",
            "placeholder": "How are you today?"
          },
          {
            "name": "iconUrl",
            "type": "string",
            "placeholder": "http://pandas.are.awesome/panda.png"
          },
          {
            "name": "contextMessage",
            "type": "string",
            "placeholder": "Pandas are awesome."
          },
          {
            "name": "requireInteraction",
            "type": "bool",
            "value": false
          }
        ],
        r"$result": "values",
        r"$columns": []
      },
      "cancelNotification": {
        r"$name": "Cancel Notification",
        r"$invokable": "write",
        r"$params": [
          {
            "name": "notificationId",
            "type": "string"
          }
        ],
        r"$result": "values",
        r"$is": "cancelNotification"
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
      },
      "windows": {
        r"$name": "Windows",
        "create": {
          r"$name": "Create",
          r"$is": "createWindow",
          r"$invokable": "write",
          r"$params": [
            {
              "name": "url",
              "type": "string",
              "placeholder": "https://www.google.com"
            },
            {
              "name": "top",
              "type": "number"
            },
            {
              "name": "left",
              "type": "number"
            },
            {
              "name": "width",
              "type": "number"
            },
            {
              "name": "height",
              "type": "number"
            },
            {
              "name": "state",
              "type": "enum[normal,minimized,maximized,fullscreen,docked]",
              "default": "normal"
            },
            {
              "name": "type",
              "type": "enum[normal,popup,panel,detached_panel]",
              "default": "normal"
            }
          ],
          r"$result": "values",
          r"$columns": [
            {
              "name": "windowId",
              "type": "number"
            }
          ]
        }
      },
      "account": {
        r"$name": "Account",
        "id": {
          r"$name": "ID",
          r"$type": "string"
        },
        "email": {
          r"$name": "Email",
          r"$type": "string"
        }
      }
    },
    profiles: {
      "speak": (String path) => new SpeakNode(path),
      "openMostVisitedSite": (String path) => new OpenMostVisitedSiteNode(path),
      "openTab": (String path) => new OpenTabNode(path),
      "eval": (String path) => new EvalNode(path),
      "readMediaStream": (String path) => new MediaCaptureNode(path),
      "takeScreenshot": (String path) => new TakeScreenshotNode(path),
      "createNotification": (String path) => new CreateNotificationAction(path),
      "cancelSpeech": (String path) => new CancelSpeechAction(path),
      "closeWindow": (String path) => new CloseWindowAction(path),
      "createWindow": (String path) => new CreateWindowAction(path),
      "closeTab": (String path) => new CloseTabAction(path),
      "updateNotification": (String path) => new UpdateNotificationAction(path),
      "cancelNotification": (String path) => new CancelNotificationAction(path),
      "updateTab": (String path) => new UpdateTabAction(path)
    }
  );

  if (chrome.wallpaper.available) {
    link.defaultNodes["setWallpaperUrl"] = {
      r"$name": "Set Wallpaper Url",
      r"$is": "setWallpaperUrl",
      r"$invokable": "config",
      r"$params": [
        {
          "name": "Url",
          "type": "string"
        },
        {
          "name": "Layout",
          "type": "enum[Stretch,Center,Center Cropped]"
        }
      ],
      r"$columns": []
    };
    link.profiles["setWallpaperUrl"] = (String path) => new SetWallpaperUrlNode(path);
  }

  await link.init();
  await setup();
  await link.connect();

  var profile = await chrome.identity.getProfileUserInfo();
  link.val("/account/email", profile.email);
  link.val("/account/id", profile.id);

  onDone(chrome.identity.onSignInChanged.listen((e) async {
    var profile = await chrome.identity.getProfileUserInfo();
    link.val("/account/email", profile.email);
    link.val("/account/id", profile.id);
  }).cancel);
}

reload() async {
  try {
    for (var x in tabCaptures.keys) {
      tabCaptures[x].stream.stop();
    }

    done();
  } catch (e) {}

  link.close();
  main();
}

Disposable mostVisitedSitesTimer;
Disposable updateTimer;

String lastMostVisitedSha;

setup() async {
  var updateWindow = (Window e) {
    link.val("/windows/${e.id}/state", e.state.value);
    link.val("/windows/${e.id}/type", e.type.value);
    link.val("/windows/${e.id}/width", e.width);
    link.val("/windows/${e.id}/height", e.height);
    link.val("/windows/${e.id}/top", e.top);
    link.val("/windows/${e.id}/left", e.left);
  };

  mostVisitedSitesTimer = Scheduler.safeEvery(const Duration(seconds: 10), () async {
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
            r"$name": "Url",
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

  updateTimer = Scheduler.safeEvery(const Duration(seconds: 1), () async {
    var windows = await chrome.windows.getAll();
    for (Window window in windows) {
      if (link.getNode("/windows/${window.id}") != null) {
        updateWindow(window);
      }
    }
  });

  onDone(mostVisitedSitesTimer.dispose);
  onDone(updateTimer.dispose);

  onDone(chrome.idle.onStateChanged.listen((state) {
    link.updateValue("/idleState", state.toString());
  }).cancel);

  var addTab = (Tab tab) {
    link.addNode("/tabs/${tab.id}", {
      r"$name": tab.title,
      "id": {
        r"$name": "ID",
        r"$type": "number",
        "?value": tab.id
      },
      "active": {
        r"$name": "Active",
        r"$type": "bool",
        "?value": tab.active
      },
      "status": {
        r"$name": "Status",
        r"$type": "string",
        "?value": tab.status
      },
      "faviconUrl": {
        r"$name": "Favicon Url",
        r"$type": "string",
        "?value": tab.favIconUrl
      },
      "title": {
        r"$name": "Title",
        r"$type": "string",
        "?value": tab.title
      },
      "url": {
        r"$name": "Url",
        r"$type": "string",
        "?value": tab.url
      },
      "windowId": {
        r"$name": "Window ID",
        r"$type": "number",
        "?value": tab.windowId
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
      },
      "close": {
        r"$name": "Close",
        r"$invokable": "write",
        r"$params": [],
        r"$columns": [],
        r"$is": "closeTab"
      },
      "update": {
        r"$name": "Update",
        r"$invokable": "write",
        r"$is": "updateTab",
        r"$params": [
          {
            "name": "url",
            "type": "string",
            "default": tab.url
          },
          {
            "name": "active",
            "type": "bool",
            "default": tab.active
          }
        ]
      }
    });
  };

  var addWindow = (Window window) {
    link.addNode("/windows/${window.id}", {
      "type": {
        r"$name": "Type",
        r"$type": "string",
        "?value": window.type.value
      },
      "state": {
        r"$name": "State",
        r"$type": "string",
        "?value": window.state.value
      },
      "focused": {
        r"$name": "Focused",
        r"$type": "bool",
        "?value": window.focused
      },
      "left": {
        r"$name": "Left",
        r"$type": "number",
        "?value": window.left
      },
      "top": {
        r"$name": "Top",
        r"$type": "number",
        "?value": window.top
      },
      "width": {
        r"$name": "Width",
        r"$type": "number",
        "?value": window.width
      },
      "height": {
        r"$name": "Height",
        r"$type": "number",
        "?value": window.height
      },
      "close": {
        r"$name": "Close",
        r"$invokable": "write",
        r"$is": "closeWindow"
      }
    });
  };

  onDone(chrome.windows.onCreated.listen((Window w) {
    addWindow(w);
  }).cancel);

  onDone(chrome.windows.onRemoved.listen((int id) {
    link.removeNode("/windows/${id}");
  }).cancel);

  var currentWindow = await chrome.windows.getCurrent();

  int lastFocused = currentWindow.focused ? currentWindow.id : -1;

  onDone(chrome.windows.onFocusChanged.listen((int id) {
    try {
      link.val("/windows/${lastFocused}/focused", false);
    } catch (e) {}
    link.val("/windows/${id}/focused", true);
    lastFocused = id;
  }).cancel);

  onDone(chrome.tabs.onCreated.listen(addTab).cancel);
  for (Window w in await chrome.windows.getAll()) {
    List<Tab> tabs = await chrome.tabs.getAllInWindow(w.id);
    tabs.forEach(addTab);
    addWindow(w);
  }

  onDone(chrome.tabs.onUpdated.listen((OnUpdatedEvent e) {
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
    link.val("/tabs/${e.tabId}/id", e.tab.id);
    link.val("/tabs/${e.tabId}/windowId", e.tab.windowId);
    link.val("/tabs/${e.tabId}/active", e.tab.active);
    link.val("/tabs/${e.tabId}/faviconUrl", e.tab.favIconUrl);
    link.val("/tabs/${e.tabId}/status", e.tab.status);

    SimpleNode updateNode = link["/tabs/${e.tabId}/update"];
    updateNode.configs[r"$params"] = [
      {
        "name": "url",
        "type": "string",
        "default": e.tab.url
      },
      {
        "name": "active",
        "type": "bool",
        "default": e.tab.active
      }
    ];
  }).cancel);

  onDone(chrome.tabs.onRemoved.listen((TabsOnRemovedEvent e) {
    link.removeNode("/tabs/${e.tabId}");
  }).cancel);

  var state = await chrome.idle.queryState(300);
  link.updateValue("/idleState", state.toString());
}

class SpeakNode extends SimpleNode {
  SpeakNode(String path) : super(path);

  @override
  Object onInvoke(Map<String, dynamic> params) async* {
    String text = params["text"];
    String voiceName = params["voiceName"];
    bool enqueue = params["enqueue"];
    String lang = params["lang"];
    num volume = params["volume"];
    num pitch = params["pitch"];
    num rate = params["rate"];

    if (enqueue == null) {
      enqueue = true;
    }

    if (lang == null) {
      lang = "en-US";
    }

    String gender = params["gender"];

    if (text == null) {
      return;
    }

    var controller = new StreamController();

    var ttsParamsObject = new JsObject.jsify({});
    var ttsParams = new TtsSpeakParams.fromProxy(ttsParamsObject);
    ttsParams.enqueue = enqueue;
    ttsParams.voiceName = voiceName;
    ttsParams.lang = lang;
    ttsParams.gender = gender;
    ttsParams.volume = volume;
    ttsParams.pitch = pitch;
    ttsParams.rate = rate;

    ttsParams.jsProxy["onEvent"] = (JsObject obj) {
      String type = obj["type"];

      var map = {
        "type": type
      };

      if (obj["charIndex"] is num) {
        map["charIndex"] = (obj["charIndex"] as num).toInt();
      }

      if (obj["errorMessage"] is String) {
        map["errorMessage"] = obj["errorMessage"];
      }

      controller.add(map);

      if (type == "end") {
        controller.close();
      }
    };

    chrome.tts.speak(text, ttsParams).then((_) {
      controller.close();
    });

    await for (Map m in controller.stream) {
      yield [
        [m]
      ];
    }
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
      new TabsCreateParams(
        url: url,
        active: active
      )
    );

    return [[tab.id]];
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
      "result": JSON.decode(
        context["JSON"].callMethod("stringify", [
          results
        ])
      )
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
      new TabsCreateParams(
        url: url,
        active: true
      )
    );
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
      [url]
    ];
  }
}

class SetWallpaperUrlNode extends SimpleNode {
  SetWallpaperUrlNode(String path) : super(path);

  @override
  onInvoke(Map<String, dynamic> params) async {
    String layout = params["Layout"] as String;
    chrome.wallpaper.setWallpaper(
      new WallpaperSetWallpaperParams(
        url: params["Url"],
        layout: new WallpaperLayout.fromProxy(new JsObject.jsify(layout))
      )
    );
    return [];
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

class CreateNotificationAction extends SimpleNode {
  CreateNotificationAction(String path) : super(path);

  @override
  onInvoke(Map<String, dynamic> params) async {
    var iconUrl = params["iconUrl"];
    var title = params["title"];
    var msg = params["message"];
    var contextMsg = params["contextMessage"];
    var priority = params["priority"];
    var requireInteraction = params["requireInteraction"];

    if (iconUrl == null || iconUrl == "") {
      iconUrl = chrome.extension.getURL("icon128.png");
    }

    if (priority is! int) {
      if (priority is num) {
        priority = priority.toInt();
      } else if (priority is String) {
        priority = int.parse(priority);
      } else {
        priority = 0;
      }
    }

    if (priority > 2) {
      priority = 2;
    }

    if (priority < -2) {
      priority = -2;
    }

    var opts = new NotificationOptions(
      type: TemplateType.BASIC,
      title: title,
      message: msg,
      contextMessage: contextMsg,
      iconUrl: iconUrl,
      priority: priority
    );
    opts.jsProxy["requireInteraction"] = requireInteraction;
    var id = await chrome.notifications.create(opts);

    return [
      [id]
    ];
  }
}

class UpdateNotificationAction extends SimpleNode {
  UpdateNotificationAction(String path) : super(path);

  @override
  onInvoke(Map<String, dynamic> params) async {
    var notificationId = params["notificationId"];
    var iconUrl = params["iconUrl"];
    var title = params["title"];
    var msg = params["message"];
    var contextMsg = params["contextMessage"];
    var priority = params["priority"];
    var requireInteraction = params["requireInteraction"];

    if (iconUrl == null || iconUrl == "") {
      iconUrl = chrome.extension.getURL("icon128.png");
    }

    if (priority is! int) {
      if (priority is num) {
        priority = priority.toInt();
      } else if (priority is String) {
        priority = int.parse(priority);
      } else {
        priority = 0;
      }
    }

    if (priority > 2) {
      priority = 2;
    }

    if (priority < -2) {
      priority = -2;
    }

    var opts = new NotificationOptions(
      type: TemplateType.BASIC,
      title: title,
      message: msg,
      contextMessage: contextMsg,
      iconUrl: iconUrl,
      priority: priority
    );
    opts.jsProxy["requireInteraction"] = requireInteraction;
    var id = await chrome.notifications.update(notificationId, opts);

    return [
      [id]
    ];
  }
}

class CancelNotificationAction extends SimpleNode {
  CancelNotificationAction(String path) : super(path);

  @override
  onInvoke(Map<String, dynamic> params) async {
    var id = params["notificationId"];

    if (id is String) {
      await chrome.notifications.clear(id);
    }
  }
}

class CancelSpeechAction extends SimpleNode {
  CancelSpeechAction(String path) : super(path);

  @override
  onInvoke(Map<String, dynamic> params) async {
    chrome.tts.stop();
  }
}

class CloseTabAction extends SimpleNode {
  CloseTabAction(String path) : super(path);

  @override
  onInvoke(Map<String, dynamic> params) async {
    var id = num.parse(path.split("/")[2]).toInt();
    chrome.tabs.remove(id);
  }
}

class CloseWindowAction extends SimpleNode {
  CloseWindowAction(String path) : super(path);

  @override
  onInvoke(Map<String, dynamic> params) async {
    var id = num.parse(path.split("/")[2]).toInt();
    chrome.windows.remove(id);
  }
}

class CreateWindowAction extends SimpleNode {
  CreateWindowAction(String path) : super(path);

  @override
  onInvoke(Map<String, dynamic> params) async {
    String url = params["url"];
    int left = asInt(params["left"]);
    int top = asInt(params["top"]);
    int width = asInt(params["width"]);
    int height = asInt(params["height"]);
    CreateType type = CreateType.VALUES.firstWhere((x) {
      return x.value.toLowerCase() == params["type"].toString().toLowerCase();
    }, orElse: () => CreateType.NORMAL);

    WindowState windowState = WindowState.VALUES.firstWhere((x) {
      return x.value.toLowerCase() == params["state"].toString().toLowerCase();
    }, orElse: () => WindowState.NORMAL);

    var opts = new WindowsCreateParams(
      url: url,
      left: left,
      top: top,
      width: width,
      height: height,
      type: type,
      state: windowState
    );
    var window = await chrome.windows.create(opts);

    return [
      [window.id]
    ];
  }
}

class UpdateTabAction extends SimpleNode {
  UpdateTabAction(String path) : super(path);

  @override
  onInvoke(Map<String, dynamic> params) async {
    var id = num.parse(path.split("/")[2]).toInt();

    String url = params["url"];
    bool active = params["active"];

    var m = new TabsUpdateParams(
      url: url,
      active: active
    );
    chrome.tabs.update(m, id);
  }
}

int asInt(m) {
  if (m is int) {
    return m;
  } else if (m is num) {
    return m.toInt();
  } else if (m is String) {
    var c = num.parse(m, (e) => null);
    if (c != null) {
      return c.toInt();
    }
    return null;
  } else {
    return null;
  }
}
