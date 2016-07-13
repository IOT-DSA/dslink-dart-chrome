library dsa.chrome.app.main;

import "package:chrome/chrome_app.dart" as chrome;

main() async {
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
