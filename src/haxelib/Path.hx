package haxelib;

import haxe.io.Path.*;
using StringTools;

abstract Path(String) to String {
  inline function new(s)
    this = removeTrailingSlashes(s);

  @:op(a - b) public function up(by:Int = 1)
    return
      if (by > 0) {
        var a = [this];
        for (i in 0...by)
          a.push('..');
        return new Path(join(a));
      }
      else new Path(this);

  @:op(a / b) static function sub(p:Path, s:String)
    return new Path(join([p, normalize(s)]));

  @:from static function ofString(s:String)
    return
      if (s == null) null;//not sure this is the best treatment of null paths
      else new Path(normalize(s.trim()));

  static public function safe(name:String)
    return name.replace('.', ',');//TODO: haxelib throws if name doesn't match ~/^[A-Za-z0-9_.-]+$/
}