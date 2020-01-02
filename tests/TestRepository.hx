import haxe.DynamicAccess;
import haxelib.*;
import MockSystem;

using tink.CoreApi;

private typedef Version = String;

private typedef MockLib = {
  versions:Array<Version>,
  ?current:Version,
  ?deps:Version->Dict,
  ?dev:String,
  ?cp:String,
  populate:Version->Entry,
}

@:asserts
class TestRepository {
  public function new() {

  }
  static function seekCp(entry:Entry) {
    return null;
  }

  static function lib(name:String, ctx:MockLib) {
    var vDirs = new DynamicAccess();

    for (v in ctx.versions) {
      var files = ctx.populate(v);

      var info:LibInfo = {
        name: name,
        version: v,
        dependencies: switch ctx.deps {
          case null: null;
          case fn: fn(v);
        },
        classPath: ctx.cp
      }

      vDirs[Path.safe(v)] = files.with({
        'haxelib.json': haxe.Json.stringify(info)
      });
    }

    var current = switch ctx.current {
      case null: ctx.versions[0];
      case v: v;
    }

    return (vDirs:Entry).with({ '.current': current, '.dev': ctx.dev }).nestedIn(Path.safe(name));
  }

  static final tink_core = lib('tink_core', {
    versions: ['1.24.0', '1.23.0', '1.22.0'],
    cp: 'src',
    populate: _ -> {
      src: {
        tink: {
          'CoreApi.hx' : 'package tink;\nusing tink.core.Future;',
          core: {
            'Future.hx': 'package tink.core; #error'
          },
        }
      },
      'README.md': '# Very importan heading'
    }
  });

  static final tink_macro = lib('tink_macro', {
    versions: ['0.18.0'],
    deps: _ -> { tink_core: '' },
    populate: _ -> {
      tink: {
        'MacroApi.hx' : 'package tink; class MacroApi {}'
      }
    }
  });

  static final tink_syntaxhub = lib('tink_syntaxhub', {
    versions: ['0.4.3', '0.3.7'],
    deps: _ -> { tink_macro: '', tink_priority: '' },
    cp: 'src',
    populate: _ -> {
      src: {
        tink: {
          'SyntaxHub.hx' : 'package tink; class SyntaxHub {}'
        }
      },
      'extraParams.hxml': '--macro tink.SyntaxHub.use()',
    }
  });

  static final tink_priority = lib('tink_priority', {
    versions: ['0.1.4', '0.1.2', '0.1.1', '0.1.0'],
    cp: 'src',
    populate: _ -> {},
  });

  function init(dir)
    return new Repository(new MockSystem(false, {}, dir), '.', '.', false);

  public function test() {

    var repo = init(tink_macro & tink_core & tink_syntaxhub & tink_priority);

    asserts.assert(repo.getLibrary('tink_core').match(Success({ ver: '1.24.0' })));
    asserts.assert(repo.getLibrary('tink_core', '1.23.0').match(Success({ ver: '1.23.0' })));
    asserts.assert(repo.getLibrary('tink_core', '2.23.0').match(Failure(_)));
    asserts.assert(init(tink_macro & tink_core & tink_syntaxhub).getLibrary('tink_syntaxhub').match(Failure(_)));

    return asserts.done();
  }
}