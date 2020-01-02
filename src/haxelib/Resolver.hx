package haxelib;

using tink.CoreApi;

class Resolver {
  static final REPNAME = 'lib';
  static final REPODIR = ".haxelib";

  final cwd:Path;
  final sys:System;

  public function new(cwd, #if sys ? #end sys) {
    this.cwd = cwd;
    this.sys = #if sys if (sys == null) StdSystem.inst else #end sys;
  }

  public function localRepoPath():Null<Path> {
    var cur = cwd;
    while (true)
      switch cur / REPODIR {
        case ret if (sys.isDir(ret)):
          return ret;
        default:
          switch cur - 1 {
            case _ == cur => true: break;
            case next: cur = next;
          }
      }

    return null;
  }

  public function globalRepoPath():Outcome<Path, Error> {

    function fromString(p:Path, how:String)
      return
        if (sys.isDir(p)) Success(p);
        else Failure(new Error('the haxelib path $p $how is not a directory'));

    function fromFile(p:Path, ?annotation:String = '')
      return switch sys.readPath(p) {
        case EFile(f):
          f.get().flatMap(s -> fromString(s, 'configured in the file $p$annotation'));
        case v:
          Failure(new Error(
            if (v == ENone) 'the file $p$annotation does not exist'
            else 'the directory $p$annotation should be a file'
          ));
      }

    switch sys.getEnv('HAXELIB_PATH') {
      case null:
      case v:
        return fromString(v, 'set via env var HAXELIB_PATH');
    }

    switch getConfigFile() {
      case cfg if (sys.isFile(cfg)): //Here we slightly diverge from std haxelib: haxelib will proceed with the other options if reading the file fails (even if the file exists)
        return fromFile(cfg, ' (default config file)');
      case _ if (sys.isWindows):
        switch sys.getEnv('HAXEPATH') {
          case null:
          case p:
            return fromString((p:Path) / REPNAME, 'derived from env var HAXEPATH');
        }
      default:
        return fromFile('/etc/.haxelib', ' (default system-wide config)');
    }

    return Failure(new Error('haxelib is not configured'));
  }

  public function repo(?global = false)
    return repoPath(global).map(Repository.new.bind(sys, cwd, _, global));

  public function repoPath(?global = false):Outcome<Path, Error> {
    if (!global)
      switch localRepoPath() {
        case null:
        case v: return Success(v);
      }

    return globalRepoPath();
  }

  public function getConfigFile():Null<Path> {
    var home:Path =
      if (sys.isWindows)
        switch sys.getEnv('USERPROFILE') {
          case null:
            switch [sys.getEnv('HOMEDRIVE'), sys.getEnv('HOMEPATH')] {
              case [null, _] | [_, null]: null;
              case [d, p]: d + p;
            }
          case v: v;
        }
      else sys.getEnv('HOME');

    return
      if (home == null) null;
      else home / '.haxelib';
  }
}