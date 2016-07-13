part of dsa.chrome;

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

class UpdateWindowAction extends SimpleNode {
  UpdateWindowAction(String path) : super(path);

  @override
  onInvoke(Map<String, dynamic> params) async {
    var id = num.parse(path.split("/")[2]).toInt();

    int left = asInt(params["left"]);
    int top = asInt(params["top"]);
    int width = asInt(params["width"]);
    int height = asInt(params["height"]);

    WindowState windowState = WindowState.VALUES.firstWhere((x) {
      return x.value.toLowerCase() == params["state"].toString().toLowerCase();
    }, orElse: () => WindowState.NORMAL);

    var opts = new WindowsUpdateParams(
      left: left,
      top: top,
      width: width,
      height: height,
      state: windowState
    );
    var window = await chrome.windows.update(id, opts);

    return [
      [window.id]
    ];
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

addWindow(Window window) {
  if (window == null) return;

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
    },
    "update": {
      r"$name": "Update",
      r"$is": "updateWindow",
      r"$invokable": "write",
      r"$params": [
        {
          "name": "top",
          "type": "number",
          "default": window.top
        },
        {
          "name": "left",
          "type": "number",
          "default": window.left
        },
        {
          "name": "width",
          "type": "number",
          "default": window.width
        },
        {
          "name": "height",
          "type": "number",
          "default": window.height
        },
        {
          "name": "state",
          "type": "enum[normal,minimized,maximized,fullscreen,docked]",
          "default": window.state.value
        }
      ],
      r"$result": "values",
      r"$columns": []
    }
  });
}

updateWindow(Window e) {
  if (e == null) return;

  uv("/windows/${e.id}/state", e.state.value);
  uv("/windows/${e.id}/type", e.type.value);
  uv("/windows/${e.id}/width", e.width);
  uv("/windows/${e.id}/height", e.height);
  uv("/windows/${e.id}/top", e.top);
  uv("/windows/${e.id}/left", e.left);

  SimpleNode updateNode = link["/windows/${e.id}/update"];
  updateNode.configs[r"$params"] = [
    {
      "name": "top",
      "type": "number",
      "default": e.top
    },
    {
      "name": "left",
      "type": "number",
      "default": e.left
    },
    {
      "name": "width",
      "type": "number",
      "default": e.width
    },
    {
      "name": "height",
      "type": "number",
      "default": e.height
    },
    {
      "name": "state",
      "type": "enum[normal,minimized,maximized,fullscreen,docked]",
      "default": e.state.value
    }
  ];
}
