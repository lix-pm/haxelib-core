package haxelib;

using tink.CoreApi;

class Repository {

  public final sys:System;
  public final cwd:Path;
  public final global:Bool;
  final root:Path;

  public function new(sys, cwd, root, global) {
    this.sys = sys;
    this.cwd = cwd;
    this.root = root;
    this.global = global;
  }

  public function getLibrary(lib:String, ?ver:String):Outcome<Library, Error> {
    var dir = root / Path.safe(lib);

    function mk(ver)
      return Library.from(lib, ver, dir / Path.safe(ver), this);

    if (Library.isPinned(ver))
      return mk(ver);

    switch sys.readFile(dir / '.dev') {
      case Success(path):
        return Library.from(lib, 'dev', path, this);
      default:
    }
    return
      switch sys.readFile(dir / '.current') {
        case Success(ver):
          mk(ver);
        case Failure(_):
          Failure(new Error('Library $lib is not installed'));
      }

  }

}