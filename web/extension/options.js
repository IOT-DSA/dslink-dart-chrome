function ready() {
  document.querySelector("#save").addEventListener("click", function (e) {
    var url = document.querySelector("#brokerUrl").value;
    var logLevel = document.querySelector("#logLevel").value;
    var linkName = document.querySelector("#linkName").value;
    var enableBrowserAccess = document.querySelector("#enableBrowserAccess").checked == true;
    var enableInputAccess = document.querySelector("#enableInputAccess").checked == true;
    var enableNotificationAccess = document.querySelector("#enableNotificationAccess").checked == true;
    var enableWallpaperAccess = document.querySelector("#enableWallpaperAccess").checked == true;
    var enableGamepadAccess = document.querySelector("#enableGamepadAccess").checked == true;
    var enableSpeechAccess = document.querySelector("#enableSpeechAccess").checked == true;

    chrome.storage.sync.set({
      "broker_url": url,
      "log_level": logLevel,
      "link_name": linkName,
      "enableBrowserAccess": enableBrowserAccess ? "true" : "false",
      "enableInputAccess": enableInputAccess ? "true" : "false",
      "enableNotificationAccess": enableNotificationAccess ? "true" : "false",
      "enableWallpaperAccess": enableWallpaperAccess ? "true" : "false",
      "enableGamepadAccess": enableGamepadAccess ? "true" : "false",
      "enableSpeechAccess": enableSpeechAccess ? "true" : "false"
    }, function () {
      chrome.extension.sendRequest("reload");
    });
  });

  function _p(name, s) {
    var input = document.querySelector("#" + name);
    if (input.type === "checkbox") {
      input.checked = s == "true";
    } else {
      input.value = s;
    }
  }

  chrome.storage.sync.get([
    "broker_url",
    "log_level",
    "link_name",
    "enableBrowserAccess",
    "enableInputAccess",
    "enableNotificationAccess",
    "enableWallpaperAccess",
    "enableGamepadAccess",
    "enableSpeechAccess"
  ], function (vals) {
    _p("brokerUrl", vals["broker_url"]);
    _p("logLevel", vals["log_level"]);
    _p("linkName", vals["link_name"]);
    _p("enableBrowserAccess", vals["enableBrowserAccess"]);
    _p("enableSpeechAccess", vals["enableSpeechAccess"]);
    _p("enableInputAccess", vals["enableInputAccess"]);
    _p("enableGamepadAccess", vals["enableGamepadAccess"]);
    _p("enableWallpaperAccess", vals["enableWallpaperAccess"]);
    _p("enableNotificationAccess", vals["enableNotificationAccess"]);
  });
}

document.addEventListener("DOMContentLoaded", ready);
