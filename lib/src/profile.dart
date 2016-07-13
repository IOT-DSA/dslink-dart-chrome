part of dsa.chrome;

updateAccountProfile() async {
  var profile = await chrome.identity.getProfileUserInfo();
  if (profile != null) {
    uv("/account/email", profile.email);
    uv("/account/id", profile.id);
  }

  onDone(chrome.identity.onSignInChanged.listen((e) async {
    var profile = await chrome.identity.getProfileUserInfo();

    if (profile != null) {
      uv("/account/email", profile.email);
      uv("/account/id", profile.id);
    }
  }).cancel);
}
