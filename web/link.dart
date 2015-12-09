import "dart:async";

import "package:dslink/browser.dart";

import "package:chrome/chrome_ext.dart" as chrome;
import "package:chrome/gen/tts.dart";
import "package:chrome/gen/top_sites.dart";
import "package:chrome/gen/tabs.dart";

import "package:crypto/crypto.dart";

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
        }
      },
      profiles: {
        "speak": (String path) => new SpeakNode(path),
        "openMostVisitedSite": (String path) => new OpenMostVisitedSiteNode(path),
        "openTab": (String path) => new OpenTabNode(path)
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
          ..add(x.url.codeUnits)
          ..add(x.title.codeUnits)).close());

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
    link.updateValue("/idleState", state);
  });

  link.updateValue("/idleState", await chrome.idle.queryState(300));
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

    Tab tab = await chrome.tabs.create(new TabsCreateParams(url: url, active: active));

    return {
      "tab": tab.id
    };
  }
}

class OpenMostVisitedSiteNode extends SimpleNode {
  OpenMostVisitedSiteNode(String path) : super(path);

  @override
  onInvoke(Map<String, dynamic> params) async {
    var p = path.split("/").take(3).join("/");
    var url = link.val("${p}/url");
    var tab = await chrome.tabs.create(new TabsCreateParams(url: url, active: true));
    return {
      "tab": tab.id
    };
  }
}

TtsSpeakParams ttsOptions = new TtsSpeakParams(
    enqueue: true,
    lang: "en-US"
);
