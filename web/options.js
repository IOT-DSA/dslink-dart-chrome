function ready() {
  document.querySelector("#save").addEventListener("click", function (e) {
    var url = document.querySelector("#brokerUrl").value;
    var logLevel = document.querySelector("#logLevel").value;
    var linkName = document.querySelector("#linkName").value;

    chrome.storage.local.set({
      "broker_url": url,
      "log_level": logLevel,
      "link_name": linkName
    }, function () {
      chrome.extension.sendRequest("reload");
    });
  });

  function _p(name, s) {
    document.querySelector("#" + name).value = s;
  }

  chrome.storage.local.get(["broker_url", "log_level", "link_name"], function (vals) {
    _p("brokerUrl", vals["broker_url"]);
    _p("logLevel", vals["log_level"]);
    _p("linkName", vals["link_name"]);
  });
}

document.addEventListener("DOMContentLoaded", ready);
