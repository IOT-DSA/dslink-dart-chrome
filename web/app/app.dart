library dsa.chrome.app.main;

import "package:chrome/chrome_app.dart" as chrome;

final String CHROME_EXT = "dkjdmcjmblhakhndnabbkmghjfgfiejm";

typedef MsgHandler(chrome.OnMessageExternalEvent e);

Map<String, Function> _msgHandlers = {};
List<chrome.BluetoothDevice> _bluetoothDevices = [];

main() async {
  onDone(chrome.runtime.onMessageExternal.listen((chrome.OnMessageExternalEvent e) {
    if (e.message is Map) {
      String type = e.message["type"];
      if (_msgHandlers[type] != null) {
        _msgHandlers[type](e);
      }
    }
  }).cancel);

  onDone(chrome.bluetooth.onDeviceAdded.listen((chrome.BluetoothDevice d) {
    _bluetoothDevices.add(d);
    chrome.runtime.sendMessage({
      "type": "bluetooth.device.added",
      "device": {
        "name": d.name,
        "address": d.address
      }
    }, CHROME_EXT);
  }).cancel);

  onDone(chrome.bluetooth.onDeviceRemoved.listen((chrome.BluetoothDevice d) {
    _bluetoothDevices.remove(d);

    chrome.runtime.sendMessage({
      "type": "bluetooth.device.removed",
      "device": {
        "name": d.name,
        "address": d.address
      }
    }, CHROME_EXT);
  }).cancel);

  _msgHandlers["bluetooth.devices.get"] = (chrome.OnMessageExternalEvent e) {
    if (e.sendResponse != null) {
      e.sendResponse({
        "devices": _bluetoothDevices.map((d) {
          return {
            "name": d.name,
            "address": d.address
          };
        }).toList()
      });
    }
  };

  onDone(() {
    _msgHandlers.clear();
    _bluetoothDevices.clear();
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
