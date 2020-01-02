package haxelib;

import haxe.ds.ReadOnlyArray;

typedef LibBuildInfo = {
  final ?ndll:String;
  final extraParams:ReadOnlyArray<String>;
  final ?cp:String;
  final lib:Library;
}

@:forward(iterator)
abstract BuildInfo(Array<LibBuildInfo>) from Array<LibBuildInfo> {
  @:to public function toLines() {
    var lines = [];

    for (l in this) {
      if (l.ndll != null)
        lines.push('-L ${l.ndll}\n');
      for (line in l.extraParams)
        lines.push(line);
      lines.push(l.cp);
      lines.push('-D ${l.lib.name}=${l.lib.ver}');
    }

    return lines;
  }

  @:to public function toString() {
    return toLines().join('\n') + '\n';
  }
}