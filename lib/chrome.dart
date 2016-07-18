library dsa.chrome;

import "dart:async";
import "dart:convert";
import "dart:html" as HTML;
import "dart:js";

import "package:dslink/browser.dart";
import "package:dslink/nodes.dart";
import "package:dslink/utils.dart";

import "package:crypto/crypto.dart";

import "package:chrome/chrome_ext.dart" as chrome;
import "package:chrome/chrome_ext.dart" show
  Window,
  WindowState,
  Tab,
  TabsCreateParams,
  WindowsCreateParams,
  WindowsUpdateParams,
  TabsUpdateParams,
  MostVisitedURL,
  NotificationOptions,
  TemplateType,
  TabsOnRemovedEvent,
  WallpaperSetWallpaperParams,
  WallpaperLayout,
  TtsSpeakParams,
  InjectDetails,
  InputImeCommitTextParams,
  OnUpdatedEvent,
  CreateType,
  StorageArea;

import "media.dart";
import "utils.dart";

part "src/setup.dart";
part "src/reload.dart";
part "src/tabs.dart";
part "src/windows.dart";
part "src/ime.dart";
part "src/speak.dart";
part "src/wallpaper.dart";
part "src/notification.dart";
part "src/most_visited.dart";
part "src/data_store.dart";
part "src/main.dart";
part "src/update.dart";
part "src/profile.dart";
part "src/done.dart";
part "src/gamepads.dart";
part "src/companion.dart";

final String COMPANION_APP_ID = "ggikobigknjapmebobpegnbkncgofgie";

Disposable updateTimer;
