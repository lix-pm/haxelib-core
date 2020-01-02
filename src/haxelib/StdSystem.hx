package haxelib;

import sys.FileSystem;
using tink.CoreApi;

class StdSystem implements System {
  static public final inst:System = new StdSystem();

  function new() {}

  public final isWindows:Bool = Sys.systemName() == 'WINDOWS';

  public function getEnv(s:String):Null<String>
    return Sys.getEnv(s);

  public function readPath(p:Path):System.FsEntry
    return
      if (FileSystem.exists(p))
        if (FileSystem.isDirectory(p)) EDirectory({});
        else EFile({
          get: () -> sys.io.File.getContent.bind(p).catchExceptions()
        });
      else ENone;
}