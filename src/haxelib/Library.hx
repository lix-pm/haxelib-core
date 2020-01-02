package haxelib;

import haxe.io.Path.*;

using StringTools;
using tink.CoreApi;

class Library {

  final repo:Repository;
  final sys:System;
  public final root:Path;
  public final name:String;
  public final ver:String;
  final info:LibInfo;

  function new(name, ver, root, repo, info) {
    this.repo = repo;
    this.root = root;
    this.name = name;
    this.ver = ver;
    this.info = info;
    this.sys = repo.sys;
  }

  static public function isPinned(ver:String)
    return switch ver {
      case null | '' | '*': false;
      default: true;
    }

  public function dependencies() {
    var ret = [],
        map = new Map();

    function add(name, lib) {
      ret.push(lib);
      map[name] = lib;
    }

    add(name, this);

    function collect(info:LibInfo)
      switch info.dependencies {
        case null:
          return null;
        case dependencies:
          for (name => ver in dependencies)
            switch map[name] {
              case null:
                switch repo.getLibrary(name, ver) {
                  case Failure(e): return e;
                  case Success(lib):
                    add(name, lib);
                    collect(lib.info);
                }
              case { ver: other }:
                if (isPinned(ver))
                  return new Error('Library ${name} has two versions included : $ver and $other;');
            }
          return null;
    }

    return
      switch collect(info) {
        case null: Success(ret);
        case e: Failure(e);
      }
  }

  public function getBuildInfo():Outcome<BuildInfo, Error>
    return
      dependencies().map(function (libs):BuildInfo return [for (l in libs) {
        ndll:
          switch l.root / 'ndll' {
            case sys.isDir(_) => false: null;
            case ndir: addTrailingSlash(ndir);
          },
        extraParams:
          switch sys.readFile(l.root / 'extraParams.hxml') {
            case Failure(_): [];
            case Success(v):
              [for (arg in v.split('\n'))
                switch arg.trim() {
                  case '' | (_.charAt(0) => '#'): continue;
                  case v: v;
                }
              ];
          },
        cp: addTrailingSlash(switch l.info.classPath {
          case null: l.root;
          case v: l.root / v;
        }),
        lib: l,
      }]);

  public function printArgs()
    return
      getBuildInfo().map(nfo -> nfo.toString());

  static public function from(name:String, ver:String, root:Path, repo:Repository):Outcome<Library, Error> {
    var info =
      repo.sys.readFile(root / 'haxelib.json')
        .flatMap(content ->
          try Success((haxe.Json.parse(content):LibInfo))
          catch (e:Dynamic) Failure(Error.withData(UnprocessableEntity, 'failed to parse ${root/'haxelib.json'}', e))
        );

    if (ver == 'dev')
      info = info.orTry(Success(({
        name: name,
        version: ver,
      }:LibInfo)));

    return info.map(info -> new Library(name, ver, root, repo, info));
  }
}