library dsa.chrome.app.main;

import "package:chrome/chrome_app.dart" as chrome;
import "package:dslink_chrome/utils.dart";

final String CHROME_EXT = "dkjdmcjmblhakhndnabbkmghjfgfiejm";

typedef MsgHandler(chrome.OnMessageEvent e, chrome.Port port, Map<String, dynamic> m);

Map<String, Function> _msgHandlers = {};
List<chrome.BluetoothDevice> _bluetoothDevices = [];
List<chrome.MdnsService> _mdnsServices = [];
List<chrome.Port> _ports = [];

void pub(m, [id]) {
  print("Publish ${m}");
  for (chrome.Port port in _ports.toList()) {
    if (id != null && port.sender.id != id) {
      continue;
    }

    try {
      port.postMessage(m);
    } catch (e) {
      _ports.remove(port);
    }
  }
}

main() async {
  onDone(() {
    for (chrome.Port port in _ports) {
      port.disconnect();
    }

    _ports.clear();
  });

  onDone(chrome.runtime.onConnectExternal.listen((chrome.Port port) {
    print("New connection from ${port.sender.id}.");
    _ports.add(port);
    port.onMessage.listen((e) {
      var msg = jsToDart(e.message);
      if (msg is Map) {
        String type = msg["type"];

        print("Got request '${type}' from ${port.sender.id}");

        if (_msgHandlers[type] != null) {
          _msgHandlers[type](e, port, msg);
        } else {
          print("Unknown request: ${type}");
        }
      }
    });

    try {
      port.onDisconnect.listen((_) {
        _ports.remove(port);
      });
    } catch (e) {}

    port.postMessage({
      "type": "runtime.connected"
    });
  }).cancel);

  onDone(chrome.bluetooth.onDeviceAdded.listen((chrome.BluetoothDevice d) {
    _bluetoothDevices.add(d);
    pub({
      "type": "bluetooth.device.added",
      "device": buildBluetoothDeviceInfo(d)
    });
  }).cancel);

  onDone(chrome.bluetooth.onDeviceChanged.listen((chrome.BluetoothDevice d) {
    _bluetoothDevices.removeWhere((x) => x.address == d.address);
    _bluetoothDevices.add(d);

    pub({
      "type": "bluetooth.device.changed",
      "device": buildBluetoothDeviceInfo(d)
    });
  }).cancel);

  onDone(chrome.bluetooth.onDeviceRemoved.listen((chrome.BluetoothDevice d) {
    _bluetoothDevices.removeWhere((x) => x.address == d.address);

    pub({
      "type": "bluetooth.device.removed",
      "device": buildBluetoothDeviceInfo(d)
    });
  }).cancel);

  onDone(chrome.bluetooth.onAdapterStateChanged.listen((chrome.AdapterState state) {
    syncAdapterState(state);
  }).cancel);

  _msgHandlers["bluetooth.devices.get"] = (chrome.OnMessageEvent e, chrome.Port port, m) {
    if (e.sendResponse != null) {
      e.sendResponse({
        "devices": _bluetoothDevices.map(buildBluetoothDeviceInfo).toList()
      });
    }
  };

  _msgHandlers["bluetooth.sync"] = (chrome.OnMessageEvent e, chrome.Port port, m) async {
    var adapterState = await chrome.bluetooth.getAdapterState();
    syncAdapterState(adapterState);
    await resyncBluetoothDevices();
    for (chrome.BluetoothDevice d in _bluetoothDevices) {
      pub({
        "type": "bluetooth.device.added",
        "device": buildBluetoothDeviceInfo(d)
      });
    }
  };

  _msgHandlers["bluetooth.discovery.start"] = (chrome.OnMessageEvent e, chrome.Port port, m) {
    chrome.bluetooth.startDiscovery();
  };

  _msgHandlers["bluetooth.discovery.stop"] = (chrome.OnMessageEvent e, chrome.Port port, m) {
    chrome.bluetooth.stopDiscovery();
  };

  _msgHandlers["mdns.discover"] = (chrome.OnMessageEvent e, chrome.Port port, m) {
    chrome.mdns.forceDiscovery();
  };

  _msgHandlers["mdns.sync"] = (chrome.OnMessageEvent e, chrome.Port port, m) {
    for (chrome.MdnsService service in _mdnsServices) {
      pub({
        "type": "mdns.services.added"
      }..addAll(buildMdnsServiceInfo(service)));
    }
  };

  onDone(chrome.mdns.onServiceList.listen((List<chrome.MdnsService> services) {
    bool match(chrome.MdnsService a, chrome.MdnsService b) {
      return a.ipAddress == b.ipAddress && a.serviceHostPort == b.serviceHostPort && a.serviceName == b.serviceName;
    };
    var newServices = services.where((s) => !_mdnsServices.any((n) => match(s, n))).toList();
    var goneServices = _mdnsServices.where((s) => !services.any((n) => match(s, n))).toList();

    for (chrome.MdnsService service in goneServices) {
      pub({
        "type": "mdns.services.removed"
      }..addAll(buildMdnsServiceInfo(service)));
    }

    for (chrome.MdnsService service in newServices) {
      pub({
        "type": "mdns.services.added"
      }..addAll(buildMdnsServiceInfo(service)));
    }

    _mdnsServices = services;
  }).cancel);

  onDone(() {
    _msgHandlers.clear();
    _bluetoothDevices.clear();
  });
}

resyncBluetoothDevices() async {
  var devs = await chrome.bluetooth.getDevices();
  devs
    .where((x) => !_bluetoothDevices.any((n) => n.address == x.address))
    .forEach(_bluetoothDevices.add);
}

Map<String, dynamic> buildBluetoothDeviceInfo(chrome.BluetoothDevice device) {
  return {
    "name": device.name,
    "address": device.address,
    "paired": device.paired,
    "connectable": device.connectable,
    "connected": device.connected,
    "connecting": device.connecting,
    "deviceType": device.type.value
  };
}

Map<String, dynamic> buildMdnsServiceInfo(chrome.MdnsService service) {
  return {
    "name": service.serviceName,
    "address": service.ipAddress,
    "port": service.serviceHostPort
  };
}

syncAdapterState(chrome.AdapterState state) {
  pub({
    "type": "bluetooth.adapter.state",
    "discovering": state.discovering,
    "powered": state.powered,
    "available": state.available,
    "name": state.name,
    "address": state.address
  });
}

onDone(Function func) {
  _dones.add(func);
}

done() {
  for (Function func in _dones) {
    func();
  }
  _dones.clear();
}

List<Function> _dones = [];
