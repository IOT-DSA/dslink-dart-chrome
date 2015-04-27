import "dart:async";
import "dart:html";

import "package:dslink/browser_client.dart";
import "package:dslink/responder.dart";
import "package:dslink/src/crypto/pk.dart";

import "package:chrome/chrome_app.dart" as chrome;
import "package:chrome/gen/tts.dart";

BrowserECDHLink link;
SimpleNodeProvider provider;

main() async {
  provider = new SimpleNodeProvider({
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
      r"$type": "enum[active,idle,locked]",
      "?value": "active"
    }
  }, {
    "speak": (String path) => new SpeakNode(path)
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

setup() async {
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

TtsSpeakParams ttsOptions = new TtsSpeakParams(
  enqueue: true,
  lang: "en-US"
);
