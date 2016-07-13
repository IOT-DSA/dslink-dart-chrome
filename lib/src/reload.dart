part of dsa.chrome;

reload() async {
  try {
    for (var x in tabCaptures.keys) {
      tabCaptures[x].stream.stop();
    }

    tabCaptures.clear();

    done();
  } catch (e) {}

  link.close();
  main();
}
