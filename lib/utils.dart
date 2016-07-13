library dsa.chrome.utils;

import "package:dslink/browser.dart";

LinkProvider link;

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

void uv(String path, dynamic val) {
  var node = link.getNode(path);
  if (node != null) {
    node.updateValue(val);
  }
}
