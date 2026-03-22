# install-autohotkey
GitHub Action to install AutoHotkey from the [AHK Downloads page](https://www.autohotkey.com/download/) and add it to the GitHub runner `PATH` variable.

## Usage

By default, the action installs the latest non-alpha release of AutoHotkey into the current working directory. You can specify the version with the `version` parameter and the output directory with the `destination` parameter. Note that the AutoHotkey executables will be installed in a new directory called "autohotkey". 

The resulting directory structure looks like this. If you need the full path to e.g. `AutoHotkey64.exe`, it is located at `$destination/autohotkey/AutoHotkey64.exe`:
```plaintext
<Destination>/
└── autohotkey/
    ├── UX (contains default AHK scripts)/
    ├── AutoHotkey64.exe
    ├── AutoHotkey32.exe
    ├── Compiler/
    │   └── Ahk2Exe.exe
    └── <...>
```

v2.1 versions are built from source, so they do not contain the UX directory and some of the other scripts (like the updater) that are included in a default AutoHotkey installation.

#### Default (Install Latest AHK v2.0 into the Current Working Directory)

Install the latest stable AutoHotkey v2.0 release into the current working directory:
```yml
- uses: holy-tao/install-autohotkey@v2
```

#### Install a Specific Version
Specify a version with the `version` parameter. This can be a version string like `v2.0.0`, with or without the leading `v` (thus, `v2.0.0` and `2.0.0` are identical), or the literal string `latest` to install the latest version (this is the default).

```yml
- uses: holy-tao/install-autohotkey@v2
  with:
    version: '2.0.19'
```

#### Install the Latest Version of a Specific Branch
Specify `{major}.{minor}-latest` to specifically install the latest version of a minor-version branch. For example, to install the latest v2.1 build:

```yml
- uses: holy-tao/install-autohotkey@v2
  with:
    version: '2.1-latest'
```

#### Install into a Specific Directory
Specify the output directory with the `destination` parameter:

```yml
- uses: holy-tao/install-autohotkey@v2
  with:
    version: '2.1-alpha.20'
    destination: '${{ runner.temp }}'
```

#### Install with the [Compiler](https://github.com/AutoHotkey/Ahk2Exe)
Specify a version of Ahk2Exe to install, or the literal string `latest` to get the latest version, in the `compiler` parameter:
```yml
- uses: holy-tao/install-autohotkey@v2
  with:
    version: 'latest'
    compiler: 'latest'
```
By default, the compiler is not installed. Note that running `install-ahk2exe` is not recommended, as it will launch the compiler Gui, which you cannot access in the headless GitHub Action runners.


## Inputs
| Name | Type | Description|
|------|------|------------|
| version | String | The version of AutoHotkey to install, or `latest` to install the latest version according to GitHub Releases. The version can be specified with or without a leading "v" - `v2.0.19` and `2.0.19` behave identically. The version selected must be available from the AutoHotkey [GitHub releases page](https://github.com/AutoHotkey/AutoHotkey/releases), _not_ the tags page.
| destination | String | The directory in which to create the `autohotkey` directory where AutoHotkey will be installed. By default, this is the current working directory. If this directory does not exist, it will be created.
| compiler | String | The version of Ahk2Exe, if any, to install. Omit or leave blank to not install Ahk2Exe (default behavior)

## Outputs
| Name | Type | Description|
|------|------|------------|
| version | String | The version of AutoHotkey that was actually installed. If the version input was not `latest` or a version-specific `latest` string, this is identical to that value, but never includes a leading "v".
| ahk32 | String | The full path to the installed AutoHotkey32.exe executable
| ahk64 | String | The full path to the installed AutoHotkey64.exe executable
| ahk2Exe | String | The full path to the installed Ahk2Exe.exe executable, only present if a compiler version was specified
