# install-autohotkey
GitHub Action to install AutoHotkey from the [GitHub releases page](https://github.com/AutoHotkey/AutoHotkey/releases) and add it to the GitHub runner `PATH` variable.

## Usage

By default, the action installs the latest non-alpha release of AutoHotkey into the current working directory. You can specify the version with the `version` parameter and the output directory with the `destination` parameter. Note that the AutoHotkey executables will be installed in a new directory called "autohotkey". 

The resulting directory structure looks like this. If you need the full path to e.g. `AutoHotkey64.exe`, it is located at `$destination/autohotkey/AutoHotkey64.exe`:
```plaintext
📂 <Destination>/
└── 📂 autohotkey/
    ├── 📂 UX (contains default AHK scripts)/
    │   ├── 📂 inc/
    │   │   ├── bounce-v1.ahk
    │   │   └── <...>
    │   ├── 📂 Templates/
    │   │   └── Minimal for v2.ahk
    │   ├── install-ahk2exe.ahk
    │   ├── install-version.ahk
    │   └── <...>
    ├── AutoHotkey64.exe
    ├── AutoHotkey32.exe
    └── <...>
```

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
    destination: '${{ runner.temp }}'
```

### Alpha Versions
Alpha versions (e.g. v2.1 versions) are not supported. Alpha release tags only include source code ([example](https://github.com/AutoHotkey/AutoHotkey/releases/tag/v2.1-alpha.18)), so installing one would require building from source. While possible, this is a much more significant effort than installing from a .zip file.

## Inputs
| Name | Type | Description|
|------|------|------------|
| version | String | The version of AutoHotkey to install, or `latest` to install the latest version according to GitHub Releases. The version can be specified with or without a leading "v" - `v2.0.19` and `2.0.19` behave identically. The version selected must be available from the AutoHotkey [GitHub releases page](https://github.com/AutoHotkey/AutoHotkey/releases), _not_ the tags page.
| destination | String | The directory in which to create the `autohotkey` directory where AutoHotkey will be installed. By default, this is the current working directory. If this directory does not exist, it will be created.
