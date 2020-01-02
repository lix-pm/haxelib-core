import haxelib.*;

using tink.CoreApi;

@:asserts
class TestResolver {

  public function new() {}

  @:variant({}, {}, null)

  @:variant({ USERPROFILE: 'foo' }, {}, null)
  @:variant({ USERPROFILE: 'foo' }, { 'foo/.haxelib': 'bar' }, null)
  @:variant({ USERPROFILE: 'foo' }, { 'foo/.haxelib': 'bar', bar: 'not a file' }, null)
  @:variant({ USERPROFILE: 'foo' }, { 'foo/.haxelib': 'bar', bar: {} }, 'bar')

  @:variant({ HOMEDRIVE: 'X:', HOMEPATH: '\\foo' }, {}, null)
  @:variant({ HOMEDRIVE: 'X:', HOMEPATH: '\\foo' }, { 'x:/foo/.haxelib': 'bar' }, null)
  @:variant({ HOMEDRIVE: 'X:', HOMEPATH: '\\foo' }, { 'x:/foo/.haxelib': 'bar', bar: 'not a file' }, null)
  @:variant({ HOMEDRIVE: 'X:', HOMEPATH: '\\foo' }, { 'x:/foo/.haxelib': 'bar', bar: {} }, 'bar')

  @:variant({ HAXELIB_PATH: 'bar' }, {}, null)
  @:variant({ HAXELIB_PATH: 'bar' }, {}, null)
  @:variant({ HAXELIB_PATH: 'bar' }, { bar: 'not a file' }, null)
  @:variant({ HAXELIB_PATH: 'bar' }, { bar: {} }, 'bar')


  @:variant({ HAXEPATH: 'awesome-haxe' }, { 'awesome-haxe/lib': {} }, 'awesome-haxe/lib')

  // precedences:
  @:variant({ USERPROFILE: 'foo', HAXELIB_PATH: 'blargh' }, { 'foo/.haxelib': 'bar', bar: {}, blargh: {} }, 'blargh')
  @:variant({ USERPROFILE: 'foo', HOMEDRIVE: 'X:', HOMEPATH: '\\foo' }, { 'foo/.haxelib': 'bar', bar: {} }, 'bar')

  public function windows(env, fs, expected:String) {
    var resolver = new Resolver('.', new MockSystem(true, env, fs));

    switch [expected, resolver.globalRepoPath()] {
      case [null, o]: asserts.assert(!o.isSuccess());
      case [_, Failure(e)]: asserts.assert(e.message == null);
      case [_, Success(p)]: asserts.assert(p == expected);
    }

    return asserts.done();
  }
}