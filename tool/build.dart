import "dart:io";

main() async {
  await build();
  await package();
}

build() async {
  var process = await Process.start("pub", ["build"]);
  stdout.addStream(process.stdout);
  stderr.addStream(process.stderr);
  var code = await process.exitCode;
  if (code != 0) {
    print("Failed to build extension.");
    exit(1);
  }
}

package() async {
  var exe = findChromeExecutable();
  var args = ["--pack-extension=${Directory.current.path}/build/web"];

  if (globalKey.existsSync()) {
    print("Signing with Global Key");
    args.add("--pack-extension-key=${globalKey.path}");
  }

  var process = await Process.start(exe.path, args);
  stdout.addStream(process.stdout);
  stderr.addStream(process.stderr);
  var code = await process.exitCode;
  if (code != 0) {
    print("Failed to package extension.");
    exit(1);
  }

  var crxDir = new Directory("build/crx");

  if (crxDir.existsSync()) {
    crxDir.deleteSync(recursive: true);
  }

  crxDir.createSync(recursive: true);

  var crxFile = new File("build/web.crx");
  crxFile.renameSync("${crxDir.path}/DSLink.crx");
  var crxKey = new File("build/web.pem");
  if (crxKey.existsSync()) {
    print("Copying Generate Key to Global Key");
    globalKey.createSync(recursive: true);
    globalKey.writeAsStringSync(crxKey.readAsStringSync());
    crxKey.deleteSync();
  }
}

File globalKey = new File("${Platform.environment["HOME"]}/.dglogik/crx.pem");

File findChromeExecutable() {
  void executableNotFound() {
    print("Failed to find Google Chrome.");
    exit(1);
  }

  if (Platform.isMacOS) {
    var appDir = new Directory("/Applications");
    var chromeApps = appDir.listSync()
      .where((it) => it is Directory && it.path.endsWith(".app") && it.path.contains("Google Chrome"))
      .toList();

    if (chromeApps.isEmpty) {
      executableNotFound();
    }

    var exeDir = new Directory("${chromeApps.first.path}/Contents/MacOS/");
    var exes = exeDir.listSync().where((it) => it is File && it.path.contains("Google Chrome")).toList();
    if (exes.isEmpty) {
      executableNotFound();
    }

    return exes.first;
  } else {
    executableNotFound();
  }

  return null;
}
