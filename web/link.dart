import "dart:async";

import "package:dslink/browser_client.dart";
import "package:dslink/responder.dart";
import "package:dslink/src/crypto/pk.dart";

import "package:chrome/chrome_ext.dart" as chrome;
import "package:chrome/gen/tts.dart";
import "package:chrome/gen/top_sites.dart";
import "package:chrome/gen/tabs.dart";

import "package:crypto/crypto.dart";

BrowserECDHLink link;
SimpleNodeProvider provider;

main() async {
  provider = new SimpleNodeProvider({
    "Open_Tab": {
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
          "type": "bool"
        }
      ],
      r"$columns": []
    },
    "Speak": {
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
    "Idle_State": {
      r"$name": "Idle State",
      r"$type": "enum[active,idle,locked]",
      "?value": "active"
    },
    "Most_Visited_Sites": {
      r"$name": "Most Visited Sites",
    }
  }, {
    "speak": (String path) => new SpeakNode(path),
    "openMostVisitedSite": (String path) => new OpenMostVisitedSiteNode(path)
  });

  var localStorage = chrome.storage.local;
  var c = await localStorage.get({
    "broker_url": "http://127.0.0.1:8080/conn",
    "dsa_key": "__GENERATE__"
  });
  String brokerUrl = c["broker_url"];
  PrivateKey key;

  if (c["dsa_key"] != "__GENERATE__") {
    key = new PrivateKey.loadFromString(c["dsa_key"]);
  } else {
    key = new PrivateKey.generate();
    await localStorage.set({
      "dsa_key": key.saveToString()
    });
  }

  await setup();

  link = new BrowserECDHLink(brokerUrl, "Chrome-", key, nodeProvider: provider);

  await link.connect();
}

Timer timer;

String lastMostVisitedSha;

setup() async {
  timer = new Timer.periodic(new Duration(seconds: 5), (_) async {
    List<MostVisitedURL> topSites = await chrome.topSites.get();

    var datas = [];
    for (var x in topSites) {
      datas.addAll(x.url.codeUnits);
      datas.add("|".codeUnitAt(0));
      datas.addAll(x.title.codeUnits);
      datas.add("|".codeUnitAt(0));
    }

    var s = CryptoUtils.bytesToHex((new SHA1()..add(datas)).close());

    if (lastMostVisitedSha == null || lastMostVisitedSha != s) {
      var c = n("/Most_Visited_Sites");
      lastMostVisitedSha = s;
      for (var x in c.children.keys) {
        c.removeChild(x);
      }

      for (var x in topSites) {
        var id = CryptoUtils.bytesToHex((new SHA1()..add(x.url.codeUnits)..add(x.title.codeUnits)).close());

        provider.addNode("/Most_Visited_Sites/${id}", {
        r"$name": x.title,
        "URL": {
        r"$type": "string",
        "?value": x.url
        },
        "Open": {
          r"$is": "openMostVisitedSite",
          r"$invokable": "write",
          r"$result": "values",
          r"$params": [],
          r"$columns": []
        }
        });
      }
    }
  });

  chrome.idle.onStateChanged.listen((state) {
    n("/Idle_State").updateValue(state);
  });

  n("/Idle_State").updateValue(await chrome.idle.queryState(300));
}

SimpleNode n(String path) {
  return provider.getNode(path);
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
  Object onInvoke(Map<String, dynamic> params) {
    if (params["url"] == null) return {};

    var url = params["url"];
    var active = params["active"];

    chrome.tabs.create(new TabsCreateParams(url: url));
  }
}

class OpenMostVisitedSiteNode extends SimpleNode {
  OpenMostVisitedSiteNode(String path) : super(path);

  @override
  Object onInvoke(Map<String, dynamic> params) {
    var p = path.split("/").take(3).join("/");
    var url = (provider.getNode(p).getChild("URL") as SimpleNode).lastValueUpdate.value;
    chrome.tabs.create(new TabsCreateParams(url: url, active: true));
    return {};
  }
}

TtsSpeakParams ttsOptions = new TtsSpeakParams(
  enqueue: true,
  lang: "en-US"
);
