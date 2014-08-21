// Copyright (c) 2014, the csso_transformer project authors. Please see
// the AUTHORS file for details. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

/* Transfomer that minifies css files with csso tool. */
library csso_transformer;

import 'dart:async';
import 'dart:io';
import 'package:barback/barback.dart';
import 'package:path/path.dart' as ospath;

/**
 * Transformer Options:
 *
 * [restructure] Enable structure minimization. DEFAULT: true
 */
class TransformerOptions {
  final bool restructure;

  TransformerOptions(this.restructure);

  factory TransformerOptions.parse(Map configuration) {
    config(key, defaultValue) {
      var value = configuration[key];
      return value != null ? value : defaultValue;
    }

    return new TransformerOptions(config('restructure', true));
  }
}

/**
 * Parses css and adds vendor prefixes to CSS rules.
 */
class CssoTransformer extends Transformer implements DeclaringTransformer {
  final BarbackSettings _settings;
  final TransformerOptions _options;

  CssoTransformer.asPlugin(BarbackSettings s)
      : _settings = s,
        _options = new TransformerOptions.parse(s.configuration);

  String get allowedExtensions => '.css';

  Future apply(Transform transform) {
    if (_settings.mode == BarbackMode.DEBUG) {
      return new Future.value();
    }

    return Directory.systemTemp.createTemp('csso-transformer-').then((dir) {
      var fileSink;

      return new Future.sync(() {
        var asset = transform.primaryInput;
        var filename = ospath.basename(asset.id.path);
        var fullpath = ospath.join(dir.path, filename);
        var file = new File(fullpath);
        fileSink = file.openWrite();
        return fileSink.addStream(asset.read());
      }).then((file) {
        return _csso(file.path, _options.restructure);
      }).then((result) {
        transform.addOutput(
            new Asset.fromString(transform.primaryInput.id, result));
      }).whenComplete(() {
        if (fileSink != null) {
          return fileSink.close();
        }
      }).whenComplete(() {
        return dir.delete(recursive: true);
      });
    });
  }

  Future declareOutputs(DeclaringTransform transform) {
    if (_settings.mode == BarbackMode.RELEASE) {
      transform.declareOutput(transform.primaryId);
    }
    return new Future.value();
  }
}

Future<String> _csso(String path, bool restructure) {
  var flags = [];
  if (!restructure) {
    flags.add('--restructure-off');
  }
  flags.add(path);

  return Process.run('csso', flags).then((result) {
    if (result.exitCode == 0) {
      return result.stdout;
    }
    throw new CssoException(result.stderr);
  }).catchError((ProcessException e) {
    throw new CssoException(e.toString());
  }, test: (e) => e is ProcessException);
}

class CssoException implements Exception {
  final String msg;

  CssoException(this.msg);

  String toString() => msg == null ? 'CssoException' : msg;
}
