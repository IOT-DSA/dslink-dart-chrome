part of dsa.chrome;

class CreateTabNode extends SimpleNode {
  CreateTabNode(String path) : super(path);

  @override
  onInvoke(Map<String, dynamic> params) async {
    if (params["url"] == null) return [];

    var url = params["url"];
    var active = params["active"];
    var windowId = asInt(params["windowId"]);

    Tab tab = await chrome.tabs.create(
      new TabsCreateParams(
        url: url,
        active: active,
        windowId: windowId
      )
    );

    return [[tab.id]];
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

class CloseTabAction extends SimpleNode {
  CloseTabAction(String path) : super(path);

  @override
  onInvoke(Map<String, dynamic> params) async {
    var id = num.parse(path.split("/")[2]).toInt();
    chrome.tabs.remove(id);
  }
}

class ReloadTabAction extends SimpleNode {
  ReloadTabAction(String path) : super(path);

  @override
  onInvoke(Map<String, dynamic> params) async {
    var id = num.parse(path.split("/")[2]).toInt();
    chrome.tabs.reload(id);
  }
}

addTab(Tab tab) {
  if (tab == null) return;

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
    "readMediaStream": {
      r"$name": "Read Media Stream",
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
    "reload": {
      r"$name": "Reload",
      r"$invokable": "write",
      r"$params": [],
      r"$columns": [],
      r"$is": "reloadTab"
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
}
