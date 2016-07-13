part of dsa.chrome;

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

setupWallpaperSupport() async {
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

    link.profiles["setWallpaperUrl"] = (String path) {
      return new SetWallpaperUrlNode(path);
    };
  }
}
