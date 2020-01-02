import haxe.DynamicAccess;
import haxelib.System;
import haxelib.Path;
import haxe.io.Path.*;
using tink.CoreApi;

class MockSystem implements System {

  final env:Map<String, String>;
  final files:Map<Path, FsEntry>;
  public final isWindows:Bool;

  public function getEnv(s:String):Null<String>
    return env[normalize(s)];

  public function readPath(p:Path):FsEntry
    return switch files[normalize(p)] {
      case null: ENone;
      case v: v;
    }

  function normalize(k:String)
    return if (isWindows) k.toUpperCase() else k;

  public function new(isWindows, env:DynamicAccess<String>, fs:Entry) {
    this.isWindows = isWindows;
    this.env = [for (k => v in env) normalize(k) => v];
    this.files = new Map();

    function crawl(e:Entry_, path:String)
      files[normalize(path)] =
        switch e {
          case Left(v):
            EFile(cast {
              get: () -> v,
              toString: () -> Std.string(v),
            });
          case Right(entries):
            for (k => v in entries)
              crawl(v, if (isAbsolute(k)) k else join([path, k]));
            EDirectory({});
        }

    crawl(fs, '');
  }

  static public function fs(fsCreator)
    return Entry.create(fsCreator);
}

private typedef Entry_ = Either<Outcome<String, Error>, DynamicAccess<Entry>>;

abstract Entry(Entry_) to Entry_ {

  public inline function new(v)
    this = v;

  @:op(a & b) public function with(that:Entry)
    return switch [this, (that:Entry_)] {
      case [Right(a), Right(b)]:
        var ret = new DynamicAccess();
        for (d in [a, b])
          for (k => v in d)
            ret[k] = v;
        new Entry(Right(ret));
      default: throw 'can only merge directories';
    }

  public function nestedIn(path:String):Entry {
    var ret = new DynamicAccess();
    ret[path] = new Entry(this);
    return ret;
  }

  // public function add()

  @:from static function ofString(s:String)
    return new Entry(Left(Success(s)));

  @:from static function ofError(e:Error)
    return new Entry(Left(Failure(e)));

  @:from static function ofDict(entries:DynamicAccess<Entry>)
    return new Entry(Right(entries));

  static public function create(fsCreator:(fs:(entries:DynamicAccess<Entry>)->Entry)->Entry)
    return fsCreator(entries -> entries);
}