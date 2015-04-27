chrome.app.runtime.onLaunched.addListener(function(launchData) {
  chrome.app.window.create('link.html', {
    'id': 'main', 'bounds': {'width': 800, 'height': 650 }
  });
});
