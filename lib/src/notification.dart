part of dsa.chrome;

class CreateNotificationAction extends SimpleNode {
  CreateNotificationAction(String path) : super(path);

  @override
  onInvoke(Map<String, dynamic> params) async {
    var iconUrl = params["iconUrl"];
    var title = params["title"];
    var msg = params["message"];
    var contextMsg = params["contextMessage"];
    var priority = params["priority"];
    var requireInteraction = params["requireInteraction"];

    if (iconUrl == null || iconUrl == "") {
      iconUrl = chrome.extension.getURL("icon128.png");
    }

    if (priority is! int) {
      if (priority is num) {
        priority = priority.toInt();
      } else if (priority is String) {
        priority = int.parse(priority);
      } else {
        priority = 0;
      }
    }

    if (priority > 2) {
      priority = 2;
    }

    if (priority < -2) {
      priority = -2;
    }

    var opts = new NotificationOptions(
      type: TemplateType.BASIC,
      title: title,
      message: msg,
      contextMessage: contextMsg,
      iconUrl: iconUrl,
      priority: priority
    );
    opts.jsProxy["requireInteraction"] = requireInteraction;
    var id = await chrome.notifications.create(opts);

    return [
      [id]
    ];
  }
}

class UpdateNotificationAction extends SimpleNode {
  UpdateNotificationAction(String path) : super(path);

  @override
  onInvoke(Map<String, dynamic> params) async {
    var notificationId = params["notificationId"];
    var iconUrl = params["iconUrl"];
    var title = params["title"];
    var msg = params["message"];
    var contextMsg = params["contextMessage"];
    var priority = params["priority"];
    var requireInteraction = params["requireInteraction"];

    if (iconUrl == null || iconUrl == "") {
      iconUrl = chrome.extension.getURL("icon128.png");
    }

    if (priority is! int) {
      if (priority is num) {
        priority = priority.toInt();
      } else if (priority is String) {
        priority = int.parse(priority);
      } else {
        priority = 0;
      }
    }

    if (priority > 2) {
      priority = 2;
    }

    if (priority < -2) {
      priority = -2;
    }

    var opts = new NotificationOptions(
      type: TemplateType.BASIC,
      title: title,
      message: msg,
      contextMessage: contextMsg,
      iconUrl: iconUrl,
      priority: priority
    );
    opts.jsProxy["requireInteraction"] = requireInteraction;
    var id = await chrome.notifications.update(notificationId, opts);

    return [
      [id]
    ];
  }
}

class CancelNotificationAction extends SimpleNode {
  CancelNotificationAction(String path) : super(path);

  @override
  onInvoke(Map<String, dynamic> params) async {
    var id = params["notificationId"];

    if (id is String) {
      await chrome.notifications.clear(id);
    }
  }
}

class ClearAllNotificationsAction extends SimpleNode {
  ClearAllNotificationsAction(String path) : super(path);

  @override
  onInvoke(Map<String, dynamic> params) async {
    JsObject notifications = await chrome.notifications.getAll();
    List<String> ids = context["Object"].callMethod("keys", [notifications]);
    ids.forEach((id) {
      chrome.notifications.clear(id);
    });
  }
}
