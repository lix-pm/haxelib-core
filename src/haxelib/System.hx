package haxelib;

using tink.CoreApi;

@:using(haxelib.System.SystemShortcuts)
interface System {
  final isWindows:Bool;
  function getEnv(s:String):Null<String>;
  function readPath(p:Path):FsEntry;
}

enum FsEntry {
  ENone;
  EFile(file:File);
  EDirectory(d:Directory);
}

typedef File = {
  function get():Outcome<String, Error>;
}

typedef Directory = {

}

class SystemShortcuts {
  static public function exists(s:System, path:Null<Path>)
    return path != null && s.readPath(path) != ENone;

  static public function isFile(s:System, path:Null<Path>)
    return path != null && s.readPath(path).match(EFile(_));

  static public function isDir(s:System, path:Null<Path>)
    return path != null && s.readPath(path).match(EDirectory(_));

  static public function readFile(s:System, path:Null<Path>, ?pos)
    return
      if (path == null) Failure(new Error('no path given'));
      else switch s.readPath(path) {
        case EFile(f): f.get();
        case ENone: Failure(new Error(NotFound, 'file not found: $path', pos));
        case EDirectory(_): Failure(new Error(MethodNotAllowed, 'cannot open directory $path as a file', pos));
      }
}