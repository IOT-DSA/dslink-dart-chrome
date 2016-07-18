library dsa.chrome.utils;

import "dart:js";
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

dynamic jsToDart(m) {
  if (m is JsArray) {
    return m.map(jsToDart);
  } else if (m is JsObject) {
    var map = {};
    for (String key in context["Object"].callMethod("keys", [m])) {
      map[key] = jsToDart(m[key]);
    }
    return map;
  } else {
    return m;
  }
}
