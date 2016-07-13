part of dsa.chrome;

setupGamepadLoop() async {
  var timer = new Timer.periodic(
    const Duration(milliseconds: 16),
    updateGamepadSystem
  );
  onDone(timer.cancel);
}

updateGamepadSystem([Timer t]) {
  HTML.window.navigator.getGamepads().forEach((gamepad) {
    if (gamepad == null) return;
    var i = 0;
    gamepad.buttons.forEach((button) {
      uv("/gamepads/${gamepad.index}/button_$i", button.value);
      i++;
    });
    i = 0;
    gamepad.axes.forEach((axis) {
      uv("/gamepads/${gamepad.index}/axis_$i", axis);
      i++;
    });
  });
}
