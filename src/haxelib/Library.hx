package haxelib;

import haxe.DynamicAccess;
import haxe.io.Path.*;

using StringTools;
using tink.CoreApi;

private typedef Dict = DynamicAccess<String>;

private typedef Info = {
  final ?dependencies:Dict;
  final ?classPath:String;
}

class Library {

  final repo:Repository;
  final sys:System;
  public final root:Path;
  public final name:String;
  public final ver:String;
  final info:Info;

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

    function collect(dependencies:Null<Dict>) {

      if (dependencies == null)
        return null;

      for (name => ver in dependencies)
        switch map[name] {
          case null:
            switch repo.getLibrary(name, ver) {
              case Failure(e): return e;
              case Success(lib):
                add(name, lib);
                collect(lib.info.dependencies);
            }
          case { ver: other }:
            if (isPinned(ver))
              return new Error('Library ${name} has two versions included : $ver and $other;');
        }
      return null;
    }

    return
      switch collect(info.dependencies) {
        case null: Success(ret);
        case e: Failure(e);
      }
  }

  function getOwnBuildInfo()
    return {
      ndll:
        switch root / 'ndll' {
          case sys.isDir(_) => false: null;
          case ndir: addTrailingSlash(ndir);
        },
      extraParams:
        switch sys.readFile(root / 'extraParams.hxml') {
          case Failure(_): [];
          case Success(v):
            [for (arg in v.split('\n'))
              switch arg.trim() {
                case '' | (_.charAt(0) => '#'): continue;
                case v: v;
              }
            ];
        },
      cp: addTrailingSlash(switch info.classPath {
        case null: root;
        case v: root / v;
      }),
      lib: this,
    }

  public function getBuildInfo()
    return
      dependencies().map(libs -> [for (l in libs) l.getOwnBuildInfo()]);

  public function printArgs()
    return
      getBuildInfo().map(libs -> {
        var lines = [];
        for (l in libs) {
          if (l.ndll != null)
            lines.push('-L ${l.ndll}\n');
          for (line in l.extraParams)
            lines.push(line);
          lines.push(l.cp);
          lines.push('-D ${l.lib.name}=${l.lib.ver}');
        }

        return lines;
      });

  static public function from(name:String, ver:String, root:Path, repo:Repository):Outcome<Library, Error> {
    var info =
      repo.sys.readFile(root / 'haxelib.json')
        .flatMap(content ->
          try Success((haxe.Json.parse(content):Info))
          catch (e:Dynamic) Failure(Error.withData(UnprocessableEntity, 'failed to parse ${root/'haxelib.json'}', e))
        );

    if (ver == 'dev')
      info = info.orTry(Success({

      }));

    return info.map(info -> new Library(name, ver, root, repo, info));
  }
}