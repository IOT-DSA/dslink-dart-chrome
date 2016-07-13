part of dsa.chrome;

class ChromeDataStore extends DataStorage {
  static const List<String> LOCAL_ONLY = const [
    "dsa_nodes"
  ];

  static final ChromeDataStore INSTANCE = new ChromeDataStore();

  @override
  Future<String> get(String key) async {
    return (await _getStorageForKey(key).get(key))[key];
  }

  @override
  Future<bool> has(String key) async {
    return (await _getStorageForKey(key).get()).containsKey(key);
  }

  @override
  Future<String> remove(String key) async {
    var value = await get(key);
    await _getStorageForKey(key).remove(key);
    return value;
  }

  @override
  Future store(String key, String value) async {
    await _getStorageForKey(key).set({
      key: value
    });
  }

  StorageArea _getStorageForKey(String key) {
    if (key.startsWith("dsa_key") || LOCAL_ONLY.contains(key)) {
      return chrome.storage.local;
    } else {
      return chrome.storage.sync;
    }
  }
}
