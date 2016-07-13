part of dsa.chrome;

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
      if (controller == null) {
        return;
      }

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
        controller = null;
      }
    };

    chrome.tts.speak(text, ttsParams);

    await for (Map m in controller.stream) {
      yield [
        [m]
      ];
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
