package haxelib;

class Library {
  final resolver:Resolver;
  final path:String;
  public function new(resolver, path) {
    this.resolver = resolver;
    this.path = path;
  }
}