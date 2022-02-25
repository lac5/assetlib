# assetlib
A simple command line tool for fetching binary files such as images or audio into a project without pushing them to source control such as git.

## Install
For Windows, you can download the .exe file in the [Releases](https://github.com/lac5/assetlib/releases) page. You'll need to manually add it to your PATH variable.

However for any OS if you have nim/nimble installed, you can install it by downloading the source code and then executing this in the command line:

```
nimble install
```

This will build it for your OS and copy the executable into `$HOME/.nimble/bin`.

## How to use
In the root of your project run this command:
```
assetlib init
```

This should create a file called `assets.json` which looks like this:
```json
{
  "sources": {
    "<source directory>": [
      "<glob pattern>"
    ]
  },
  "assets": {
    ".": {}
  }
}
```

In this JSON object under `"sources"`, replace `<source directory>` with the directory that you keep *the original asset files* (such as a shared folder) and `<glob pattern>` with whatever pattern to match the files (for example `*.jpg`). You can have multiple source directories and each one can have multiple glob patterns. Under `"assets"`, put where to scan for asset files *in this current project* with relative path to the directory of `assets.json`. Under each directory will be a list of all the asset files' relative paths to that directory as the key and their SHA1 checksum as the value.

Next, run this command:
```
assetlib scan
```

This will scan the folders in `"assets"` and calculate the files' checksums. You can then push `assets.json` without pushing the files. Any time you make changes, run `assetlib scan` again to update `assets.json`.

When you need to pull new files or changes to files, run this command:
```
assetlib pull
```

This will scan the source directories for matching files and copy them into the project. For files to match, two conditions must be met:
1. The file names are the same. (example: `image.jpg`)
2. The checksums are the same.

### Environment Variables
It may be necessary to change the source directories based on environment or to keep them a secret. In that case you can create a file called `assets.env` in the same location as `assets.json`.

If you have this in `assets.env`:
```env
ASSETS=/usr/me/assets
```

Then you can have this in assets.json:
```json
{
  "sources": {
    "${ASSETS}": [
      "*.jpg"
    ]
  },
  "assets": {
    ".": {
      "image.jpg": "79dc9d4c41c7ed5c8131c9a139cae7693ac40419"
    }
  }
}
```

This will replace `${ASSETS}` with `/usr/me/assets` when running `assetlib pull`. You can also use any environment variable. Any `${}` that has an existing variable in the key names under `"sources"` and `"assets"` will be replaced during `assetlib scan` and `assetlib pull`. If the variable doesn't exist, the `${}` will be left as is. You can then add `assets.env` in `.gitignore` to hide the variables. 