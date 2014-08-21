# [csso](https://github.com/css/csso)_transformer

> [pub](https://pub.dartlang.org/) transformer that minifies css files
> with csso tool.

## Prerequisites

This transformer depends on [csso](https://github.com/css/csso) CLI
tool that performs transformations.

## Usage example

### `pubspec.yaml`

```yaml
name: csso_example
dependencies:
  csso_transformer: any
transformers:
- csso_transformer
```

## Options

### `restructure`

Enable structure minimization.

TYPE: `bool`  
DEFAULT: `true`
