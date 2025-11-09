# install-autohotkey
GitHub Action to install AutoHotkey from the [GitHub releases page](https://github.com/AutoHotkey/AutoHotkey/releases) and add it to the GitHub runner `PATH` variable.

### Usage

By default, the action installs the latest non-alpha release of AutoHotkey into the current working directory. You can specify the version with the `version` parameter and the output directory with the `destination` parameter.

#### Default (Install Latest into the Current Working Directory)

Install the latest AutoHotkey release into the current working directory:
```yml
- uses: holy-tao/install-autohotkey@v1
```

#### Install a Specific Version
Specify a version with the `version` parameter. This can be a version string like `v2.0.0`, with or without the leading `v` (thus, `v2.0.0` and `2.0.0` are identical), or the literal string `latest` to install the latest version (this is the default).

```yml
- uses: holy-tao/install-autohotkey@v1
  with:
    version: '2.0.19'
```

#### Install into a Specific Directory
Specify the output directory with the `destination` parameter:

```yml
- uses: holy-tao/install-autohotkey@v1
  with:
    version: '2.0.19'
    destination: '${{ runner.temp }}\ahk'
```

### Alpha Versions
Alpha versions (e.g. v2.1 versions) are not supported. Alpha release tags only include source code ([example](https://github.com/AutoHotkey/AutoHotkey/releases/tag/v2.1-alpha.18)), so installing one would require building from source. While possible, this is a much more significant effort than installing from a .zip file.