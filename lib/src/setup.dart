part of dsa.chrome;

bool enableBrowserAccess = true;
bool enableGamepadAccess = true;
bool enableInputAccess = true;
bool enableWallpaperAccess = true;
bool enableNotificationAccess = true;
bool enableSpeechAccess = true;

setup() async {
  if (enableBrowserAccess) {
    mostVisitedSitesTimer = Scheduler.safeEvery(
      const Duration(seconds: 10),
      updateMostVisited
    );
    onDone(mostVisitedSitesTimer.dispose);
  }

  updateTimer = Scheduler.safeEvery(const Duration(seconds: 1), update);

  onDone(updateTimer.dispose);

  onDone(chrome.idle.onStateChanged.listen((state) {
    link.updateValue("/idleState", state.toString());
  }).cancel);

  if (enableBrowserAccess) {
    onDone(chrome.windows.onCreated.listen((Window w) {
      addWindow(w);
    }).cancel);

    onDone(chrome.windows.onRemoved.listen((int id) {
      link.removeNode("/windows/${id}");
    }).cancel);
    var currentWindow = await chrome.windows.getCurrent();

    int lastFocused = -1;

    if (currentWindow != null) {
      if (currentWindow != null && currentWindow.focused == true) {
        lastFocused = currentWindow.id;
      }
    }

    onDone(chrome.windows.onFocusChanged.listen((int id) {
      var windowNode = link.getNode("/windows/${id}");

      if (windowNode != null) {
        uv("/windows/${lastFocused}/focused", false);
      }

      windowNode = link.getNode("/windows/${id}");

      if (windowNode != null) {
        uv("${windowNode.path}/focused", true);
      }

      lastFocused = id;
    }).cancel);

    onDone(chrome.tabs.onCreated.listen(addTab).cancel);

    for (Window w in await chrome.windows.getAll()) {
      if (w != null) {
        List<Tab> tabs = await chrome.tabs.getAllInWindow(w.id);
        tabs.forEach(addTab);
        addWindow(w);
      }
    }

    onDone(chrome.tabs.onUpdated.listen((OnUpdatedEvent e) {
      SimpleNode node = link["/tabs/${e.tabId}"];
      if (node == null) {
        return;
      }

      if (node.configs[r"$name"] != e.tab.title) {
        node.configs[r"$name"] = e.tab.title;
        node.updateList(r"$name");
      }

      uv("/tabs/${e.tabId}/title", e.tab.title);
      uv("/tabs/${e.tabId}/url", e.tab.url);
      uv("/tabs/${e.tabId}/id", e.tab.id);
      uv("/tabs/${e.tabId}/windowId", e.tab.windowId);
      uv("/tabs/${e.tabId}/active", e.tab.active);
      uv("/tabs/${e.tabId}/faviconUrl", e.tab.favIconUrl);
      uv("/tabs/${e.tabId}/status", e.tab.status);

      SimpleNode updateNode = link["/tabs/${e.tabId}/update"];
      updateNode.configs[r"$params"] = [
        {
          "name": "url",
          "type": "string",
          "default": e.tab.url
        },
        {
          "name": "active",
          "type": "bool",
          "default": e.tab.active
        }
      ];
    }).cancel);

    onDone(chrome.tabs.onRemoved.listen((TabsOnRemovedEvent e) {
      link.removeNode("/tabs/${e.tabId}");
    }).cancel);
  }

  var state = await chrome.idle.queryState(300);
  link.updateValue("/idleState", state.toString());
}
