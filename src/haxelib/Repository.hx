package haxelib;

using tink.CoreApi;

class Repository {

  final sys:System;
  final cwd:Path;
  final root:String;
  final global:Bool;

  @:allow(haxelib.Resolver)
  function new(sys, cwd, root, global) {
    this.sys = sys;
    this.cwd = cwd;
    this.root = root;
    this.global = global;
  }

  public function getLibrary(lib:String):Outcome<Library, String> {
    return Failure('not implemented');
  }

}