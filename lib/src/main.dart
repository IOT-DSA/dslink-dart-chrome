part of dsa.chrome;

main() async {
  imeManager = new ChromeIMEManager();
  imeManager.init();

  onDone(chrome.storage.onChanged.listen((e) {
    if (e.areaName == "sync") {
      if (const [
        "broker_url",
        "link_name",
        "log_level"
      ].any((x) => e.changes.containsKey(x))) {
        reload();
      }
    }
  }).cancel);

  onDone(chrome.extension.onRequest.listen((chrome.OnRequestEvent e) {
    print("Received Request: ${e.request}");

    if (e.request == "reload") {
      reload();
    }
  }).cancel);

  {
    var store = await chrome.storage.sync.get();
    var replace = {};

    if (store["broker_url"] is! String) {
      replace["broker_url"] = "http://127.0.0.1:8080/conn";
    }

    if (store["log_level"] is! String) {
      replace["log_level"] = "INFO";
    }

    if (store["link_name"] is! String) {
      replace["link_name"] = "Chrome";
    }

    if (replace.isNotEmpty) {
      await chrome.storage.sync.set(replace);
    }
  }

  updateLogLevel(await ChromeDataStore.INSTANCE.get("log_level"));
  var brokerUrl = await ChromeDataStore.INSTANCE.get("broker_url");
  var linkName = await ChromeDataStore.INSTANCE.get("link_name");

  if (!linkName.endsWith("-")) {
    linkName += "-";
  }

  onDone(HTML.window.on["gamepadconnected"].listen((event) {
    var gamepad = HTML.window.navigator.getGamepads()[event.gamepad.index];
    var gamepadStructure = {};
    var i = 0;
    gamepad.buttons.forEach((button) {
      gamepadStructure["button_$i"] = {
        r"$name": "Button $i",
        r"$type": "number"
      };
      i++;
    });
    i = 0;
    gamepad.axes.forEach((axis) {
      gamepadStructure["axis_$i"] = {
        r"$name": "Axis $i",
        r"$type": "number"
      };
      i++;
    });
    link.addNode("/gamepads/${event.gamepad.index}", gamepadStructure);
  }).cancel);

  onDone(HTML.window.on["gamepaddisconnected"].listen((event) {
    link.removeNode("/gamepads/${event.gamepad.index}");
  }).cancel);

  setupGamepadLoop();

  link = new LinkProvider(
    brokerUrl,
    linkName,
    defaultNodes: {
      "readDesktopStream": {
        r"$name": "Read Desktop Stream",
        r"$invokable": "read",
        r"$is": "readDesktopStream",
        r"$params": [
        ],
        r"$columns": [
          {
            "name": "data",
            "type": "binary"
          }
        ],
        r"$result": "stream"
      },
      "speak": {
        r"$name": "Speak",
        r"$is": "speak",
        r"$invokable": "write",
        r"$result": "stream",
        r"$params": [
          {
            "name": "text",
            "type": "string"
          },
          {
            "name": "lang",
            "type": "string",
            "default": "en-US"
          },
          {
            "name": "rate",
            "type": "number",
            "default": 1.0
          },
          {
            "name": "pitch",
            "type": "number",
            "default": 1.0
          },
          {
            "name": "gender",
            "type": "enum[female,male]",
            "default": "female"
          },
          {
            "name": "volume",
            "type": "number",
            "default": 1.0
          },
          {
            "name": "voiceName",
            "type": "string",
            "default": ""
          },
          {
            "name": "enqueue",
            "type": "bool",
            "default": true
          }
        ],
        r"$columns": [
          {
            "name": "ttsEvent",
            "type": "map"
          }
        ]
      },
      "cancelSpeech": {
        r"$name": "Cancel Speech",
        r"$invokable": "write",
        r"$result": "values",
        r"$is": "cancelSpeech",
        r"$columns": [],
        r"$params": []
      },
      "createNotification": {
        r"$name": "Create Notification",
        r"$invokable": "write",
        r"$is": "createNotification",
        r"$params": [
          {
            "name": "title",
            "type": "string",
            "placeholder": "Hello World"
          },
          {
            "name": "message",
            "type": "string",
            "placeholder": "How are you today?"
          },
          {
            "name": "iconUrl",
            "type": "string",
            "placeholder": "http://pandas.are.awesome/panda.png"
          },
          {
            "name": "contextMessage",
            "type": "string",
            "placeholder": "Pandas are awesome."
          },
          {
            "name": "requireInteraction",
            "type": "bool",
            "value": false
          }
        ],
        r"$result": "values",
        r"$columns": [
          {
            "name": "notificationId",
            "type": "string"
          }
        ]
      },
      "updateNotification": {
        r"$name": "Update Notification",
        r"$invokable": "write",
        r"$is": "updateNotification",
        r"$params": [
          {
            "name": "notificationId",
            "type": "string",
            "placeholder": "123e4567-e89b-12d3-a456-426655440000"
          },
          {
            "name": "title",
            "type": "string",
            "placeholder": "Hello World"
          },
          {
            "name": "message",
            "type": "string",
            "placeholder": "How are you today?"
          },
          {
            "name": "iconUrl",
            "type": "string",
            "placeholder": "http://pandas.are.awesome/panda.png"
          },
          {
            "name": "contextMessage",
            "type": "string",
            "placeholder": "Pandas are awesome."
          },
          {
            "name": "requireInteraction",
            "type": "bool",
            "value": false
          }
        ],
        r"$result": "values",
        r"$columns": []
      },
      "cancelNotification": {
        r"$name": "Cancel Notification",
        r"$invokable": "write",
        r"$params": [
          {
            "name": "notificationId",
            "type": "string"
          }
        ],
        r"$result": "values",
        r"$is": "cancelNotification"
      },
      "clearAllNotifications": {
        r"$name": "Clear All Notifications",
        r"$invokable": "write",
        r"$result": "values",
        r"$is": "clearAllNotifications"
      },
      "idleState": {
        r"$name": "Idle State",
        r"$type": "enum[active,idle,locked]",
        "?value": "active"
      },
      "mostVisitedSites": {
        r"$name": "Most Visited Sites",
      },
      "activeTab": {
        r"$name": "Active Tab",
        r"$type": "number",
        "?value": -1
      },
      "tabs": {
        r"$name": "Tabs",
        "create": {
          r"$is": "createTab",
          r"$name": "Create",
          r"$invokable": "write",
          r"$result": "values",
          r"$params": [
            {
              "name": "url",
              "type": "string"
            },
            {
              "name": "active",
              "type": "bool",
              "default": true
            },
            {
              "name": "windowId",
              "type": "number"
            }
          ],
          r"$columns": [
            {
              "name": "tab",
              "type": "int"
            }
          ]
        }
      },
      "windows": {
        r"$name": "Windows",
        "create": {
          r"$name": "Create",
          r"$is": "createWindow",
          r"$invokable": "write",
          r"$params": [
            {
              "name": "url",
              "type": "string",
              "placeholder": "https://www.google.com"
            },
            {
              "name": "top",
              "type": "number"
            },
            {
              "name": "left",
              "type": "number"
            },
            {
              "name": "width",
              "type": "number"
            },
            {
              "name": "height",
              "type": "number"
            },
            {
              "name": "state",
              "type": "enum[normal,minimized,maximized,fullscreen,docked]",
              "default": "normal"
            },
            {
              "name": "type",
              "type": "enum[normal,popup,panel,detached_panel]",
              "default": "normal"
            }
          ],
          r"$result": "values",
          r"$columns": [
            {
              "name": "windowId",
              "type": "number"
            }
          ]
        }
      },
      "account": {
        r"$name": "Account",
        "id": {
          r"$name": "ID",
          r"$type": "string"
        },
        "email": {
          r"$name": "Email",
          r"$type": "string"
        }
      },
      "gamepads": {
        r"$name": "Gamepads"
      },
      "typeText": {
        r"$name": "Type Text",
        r"$invokable": "write",
        r"$params": [
          {
            "name": "text",
            "type": "string",
            "editor": "textarea"
          }
        ],
        r"$is": "typeText"
      }
    },
    profiles: {
      "speak": (String path) => new SpeakNode(path),
      "openMostVisitedSite": (String path) => new OpenMostVisitedSiteNode(path),
      "createTab": (String path) => new CreateTabNode(path),
      "eval": (String path) => new EvalNode(path),
      "readMediaStream": (String path) => new MediaCaptureNode(path),
      "readDesktopStream": (String path) => new DesktopCaptureAction(path),
      "takeScreenshot": (String path) => new TakeScreenshotNode(path),
      "createNotification": (String path) => new CreateNotificationAction(path),
      "cancelSpeech": (String path) => new CancelSpeechAction(path),
      "closeWindow": (String path) => new CloseWindowAction(path),
      "createWindow": (String path) => new CreateWindowAction(path),
      "updateWindow": (String path) => new UpdateWindowAction(path),
      "closeTab": (String path) => new CloseTabAction(path),
      "reloadTab": (String path) => new ReloadTabAction(path),
      "updateNotification": (String path) => new UpdateNotificationAction(path),
      "cancelNotification": (String path) => new CancelNotificationAction(path),
      "clearAllNotifications": (String path) => new ClearAllNotificationsAction(path),
      "updateTab": (String path) => new UpdateTabAction(path),
      "typeText": (String path) => new TypeTextAction(path),
      "startBluetoothDiscovery": (String path) => new SimpleActionNode(path, (Map<String, dynamic> m) {
        startBluetoothDiscover();
      }),
      "stopBluetoothDiscovery": (String path) => new SimpleActionNode(path, (Map<String, dynamic> m) {
        stopBluetoothDiscover();
      }),
      "mdnsDiscover": (String path) => new SimpleActionNode(path, (Map<String, dynamic> m) {
        forceMdnsDiscover();
      })
    },
    dataStore: ChromeDataStore.INSTANCE
  );

  await setupWallpaperSupport();

  await link.init();
  await setup();
  await link.connect();

  await updateAccountProfile();

  runZoned(() async {
    await checkIfCompanionEnabledAndGo();
  }, onError: (e, stack) {
    print("Companion Support Failed: ${e}\n${stack}");
  });
}
