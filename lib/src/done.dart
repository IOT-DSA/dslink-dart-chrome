part of dsa.chrome;

List<Function> _dones = [];

onDone(Function e) {
  _dones.add(e);
}

done() {
  while (_dones.isNotEmpty) {
    _dones.removeAt(0)();
  }
}
