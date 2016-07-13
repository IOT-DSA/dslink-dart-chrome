part of dsa.chrome;

update() async {
  var windows = await chrome.windows.getAll();
  for (Window window in windows) {
    if (link.getNode("/windows/${window.id}") != null) {
      updateWindow(window);
    }
  }

  var currentTab = await chrome.tabs.getSelected();

  if (currentTab != null) {
    uv("/activeTab", currentTab.id);
  }
}
