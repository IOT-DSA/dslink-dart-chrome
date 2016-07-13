part of dsa.chrome;

ChromeIMEManager imeManager;

class ChromeIMEManager {
  int currentContextID;

  void init() {
    try {
      if (!chrome.input.ime.available) {
        return;
      }
    } catch (e) {
      return;
    }

    onDone(chrome.input.ime.onFocus.listen((chrome.InputContext ctx) {
      currentContextID = ctx.contextID;
    }).cancel);

    onDone(chrome.input.ime.onBlur.listen((int contextID) {
      if (currentContextID == contextID) {
        currentContextID = null;
      }
    }).cancel);
  }

  void type(String text) {
    if (currentContextID != null) {
      chrome.input.ime.commitText(new InputImeCommitTextParams(
        contextID: currentContextID,
        text: text
      ));
    }
  }
}

class TypeTextAction extends SimpleNode {
  TypeTextAction(String path) : super(path);

  @override
  onInvoke(Map<String, dynamic> params) {
    imeManager.type(params["text"]);
    return [];
  }
}
