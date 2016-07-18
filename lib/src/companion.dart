part of dsa.chrome;

typedef MsgHandler(chrome.OnMessageEvent e, Map<String, dynamic> m);

Map<String, MsgHandler> _companionHandlers = {};

checkIfCompanionEnabledAndGo() async {
  onDone(chrome.management.onInstalled.listen((chrome.ExtensionInfo e) {
    if (e.id == COMPANION_APP_ID) {
      setupCompanionNow();
    }
  }).cancel);

  var ext = await chrome.management.get(COMPANION_APP_ID);

  if (ext == null || ext.id != COMPANION_APP_ID) {
    return;
  }

  await setupCompanionNow();
}

chrome.Port _companion;

setupCompanionNow() async {
  _companion = chrome.runtime.connect(COMPANION_APP_ID);
  print("Connecting to companion...");

  _companionHandlers["runtime.connected"] = (chrome.OnMessageEvent e, m) {
    print("Connected to companion.");
  };

  onDone(_companion.onMessage.listen((e) {
    var msg = jsToDart(e.message);

    if (msg is Map) {
      var type = msg["type"];
      var handler = _companionHandlers[type];

      print("Got message '${type}' from companion.");

      if (handler != null) {
        handler(e, msg);
      }
    }
  }).cancel);
  onDone(_companion.disconnect);

  onDone(() {
    _companionHandlers.clear();
  });

  link.addNode("/bluetooth", {
    "@companion": true,
    r"$name": "Bluetooth",
    "adapter": {
      "startBluetoothDiscovery": {
        r"$name": "Start Discovery",
        r"$is": "startBluetoothDiscovery",
        r"$invokable": "write"
      },
      "stopBluetoothDiscovery": {
        r"$name": "Stop Discovery",
        r"$is": "stopBluetoothDiscovery",
        r"$invokable": "write"
      },
      "name": {
        r"$name": "Name",
        r"$type": "string",
        "?value": ""
      },
      "address": {
        r"$name": "Address",
        r"$type": "string",
        "?value": ""
      },
      r"$name": "Adapter",
      "available": {
        r"$name": "Available",
        r"$type": "bool",
        "?value": false
      },
      "powered": {
        r"$name": "Powered",
        r"$type": "bool",
        "?value": false
      },
      "discovering": {
        r"$name": "Discovering",
        r"$type": "bool",
        "?value": false
      }
    },
    "devices": {
      r"$name": "Devices"
    }
  });

  link.addNode("/mdns", {
    r"$name": "MDNS",
    "discover": {
      r"$name": "Discover",
      r"$invokable": "read",
      r"$is": "mdnsDiscover"
    },
    "services": {
      r"$name": "Services"
    }
  });

  _companionHandlers["bluetooth.device.added"] = (chrome.OnMessageEvent e, m) {
    if (m["device"] is Map) {
      Map device = m["device"];
      String name = device["name"];
      String address = device["address"];
      String deviceType = device["deviceType"];
      String rname = NodeNamer.createName(address);
      bool paired = device["paired"];
      bool connectable = device["connectable"];
      bool connected = device["connected"];
      bool connecting = device["connecting"];

      var node = link.getNode("/bluetooth/devices/${rname}");

      if (node != null) {
        return;
      }

      link.addNode("/bluetooth/devices/${rname}", {
        r"$name": name,
        "name": {
          r"$name": "Name",
          r"$type": "string",
          "?value": name
        },
        "address": {
          r"$name": "Address",
          r"$type": "string",
          "?value": address
        },
        "deviceType": {
          r"$name": "Device Type",
          r"$type": "string",
          "?value": deviceType
        },
        "connectable": {
          r"$name": "Connectable",
          r"$type": "bool",
          "?value": connectable
        },
        "connecting": {
          r"$name": "Connecting",
          r"$type": "bool",
          "?value": connecting
        },
        "connected": {
          r"$name": "Connected",
          r"$type": "bool",
          "?value": connected
        },
        "paired": {
          r"$name": "Paired",
          r"$type": "bool",
          "?value": paired
        }
      });
    }
  };

  _companionHandlers["bluetooth.device.removed"] = (chrome.OnMessageEvent e, m) {
    if (m["device"] is Map) {
      Map device = m["device"];
      String address = device["address"];
      String rname = NodeNamer.createName(address);

      link.removeNode("/bluetooth/devices/${rname}");
    }

    if (e.sendResponse != null) {
      e.sendResponse({});
    }
  };

  _companionHandlers["mdns.services.added"] = (chrome.OnMessageEvent e, m) {
    String name = m["name"];
    String address = m["address"];
    int port = m["port"];
    String rname = NodeNamer.createName("${name}:${address}:${port}");
    var node = link.getNode("/mdns/services/${rname}");
    if (node == null) {
      node = link.addNode("/mdns/services/${rname}", {
        r"$name": name,
        "name": {
          r"$name": "Name",
          r"$type": "string"
        },
        "address": {
          r"$name": "Address",
          r"$type": "string"
        },
        "port": {
          r"$name": "Port",
          r"$type": "number"
        }
      });
    }
  };

  _companionHandlers["mdns.services.removed"] = (chrome.OnMessageEvent e, m) {
    String name = m["name"];
    String address = m["address"];
    int port = m["port"];
    String rname = NodeNamer.createName("${name}:${address}:${port}");

    link.removeNode("/mdns/services/${rname}");
  };

  _companionHandlers["bluetooth.device.changed"] = (chrome.OnMessageEvent e, m) {
    if (m["device"] is Map) {
      Map device = m["device"];
      String name = device["name"];
      String address = device["address"];
      String deviceType = device["deviceType"];
      bool paired = device["paired"];
      bool connectable = device["connectable"];
      bool connected = device["connected"];
      bool connecting = device["connecting"];
      String rname = NodeNamer.createName(address);

      var node = link.getNode("/bluetooth/devices/${rname}");

      if (node == null) {
        return;
      }

      uv("/bluetooth/devices/${rname}/name", name);
      uv("/bluetooth/devices/${rname}/address", address);
      uv("/bluetooth/devices/${rname}/deviceType", deviceType);
      uv("/bluetooth/devices/${rname}/paired", paired);
      uv("/bluetooth/devices/${rname}/connectable", connectable);
      uv("/bluetooth/devices/${rname}/connected", connected);
      uv("/bluetooth/devices/${rname}/connecting", connecting);
    }
  };

  _companionHandlers["bluetooth.adapter.state"] = (chrome.OnMessageEvent e, m) {
    bool discovering = m["discovering"];
    bool available = m["available"];
    bool powered = m["powered"];
    String name = m["name"];
    String address = m["address"];

    uv("/bluetooth/adapter/name", name);
    uv("/bluetooth/adapter/address", address);
    uv("/bluetooth/adapter/discovering", discovering);
    uv("/bluetooth/adapter/powered", powered);
    uv("/bluetooth/adapter/available", available);
  };

  _companion.postMessage({
    "type": "bluetooth.sync"
  });

  _companion.postMessage({
    "type": "mdns.sync"
  });
}

startBluetoothDiscover() {
  if (_companion != null) {
    _companion.postMessage({
      "type": "bluetooth.discovery.start"
    });
  }
}

stopBluetoothDiscover() {
  if (_companion != null) {
    _companion.postMessage({
      "type": "bluetooth.discovery.stop"
    });
  }
}

forceMdnsDiscover() {
  if (_companion != null) {
    _companion.postMessage({
      "type": "mdns.discover"
    });
  }
}
