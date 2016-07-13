part of dsa.chrome;

Disposable mostVisitedSitesTimer;
String lastMostVisitedSha;

class OpenMostVisitedSiteNode extends SimpleNode {
  OpenMostVisitedSiteNode(String path) : super(path);

  @override
  onInvoke(Map<String, dynamic> params) async {
    var p = path.split("/").take(3).join("/");
    var url = link.val("${p}/url");
    var tab = await chrome.tabs.create(
      new TabsCreateParams(
        url: url,
        active: true
      )
    );
    return [[tab.id]];
  }
}

updateMostVisited() async {
  List<MostVisitedURL> topSites = await chrome.topSites.get();

  var datas = [];
  for (var x in topSites) {
    datas.addAll(x.url.codeUnits);
    datas.add("|".codeUnitAt(0));
    datas.addAll(x.title.codeUnits);
    datas.add("|".codeUnitAt(0));
  }

  var s = sha1.convert(datas).toString();

  if (lastMostVisitedSha == null || lastMostVisitedSha != s) {
    var c = link["/mostVisitedSites"];
    lastMostVisitedSha = s;
    for (var x in c.children.keys) {
      c.removeChild(x);
    }

    for (var x in topSites) {
      var id = sha1.convert(
        []
          ..addAll(x.url.codeUnits)
          ..addAll(x.title.codeUnits)
      ).toString();

      link.addNode("/mostVisitedSites/${id}", {
        r"$name": x.title,
        "url": {
          r"$name": "Url",
          r"$type": "string",
          "?value": x.url
        },
        "open": {
          r"$name": "Open",
          r"$is": "openMostVisitedSite",
          r"$invokable": "write",
          r"$result": "values",
          r"$params": [],
          r"$columns": [
            {
              "name": "tab",
              "type": "int"
            }
          ]
        }
      });
    }
  }
}
