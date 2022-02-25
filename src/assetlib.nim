from os import
  joinPath,
  getCurrentDir,
  setCurrentDir,
  fileExists,
  envPairs,
  splitPath,
  copyFile,
  createDir
from tables import
  Table,
  TableRef,
  newTable,
  pairs,
  `[]`,
  `[]=`
from options import
  Option,
  some,
  none,
  isSome,
  get
from json import
  parseFile,
  to,
  pretty,
  `%`,
  `[]`,
  `[]=`
from strutils import
  dedent,
  toLower,
  replace,
  multiReplace,
  split
from std/sha1 import
  secureHashFile,
  parseSecureHash,
  `$`,
  `==`
from glob import
  Glob,
  walkGlob,
  glob,
  matches
from dotenv import
  initDotEnv,
  load

# comment

type AssetsJson = object
  sources: TableRef[string, seq[string]]
  assets: TableRef[string, TableRef[string, string]]

proc getAssetsJson(fileName: string): AssetsJson = 
  result = parseFile(fileName).to(AssetsJson)

proc setAssetJson(fileName: string, assetsJson: AssetsJson) =
  writeFile(fileName, pretty(%assetsJson))

proc getVariables(fileName: string): seq[(string, string)] =
  result = @[]
  if fileExists(fileName):
    initDotEnv(".", fileName).load()
  for key, value in envPairs():
    result.insert(("${" & key.string & "}", value.string))

proc init(manifest = "assets.json") =
  ## Initialize a manifest file
  if not fileExists(manifest):
    var defaultAssets = new(AssetsJson)
    defaultAssets.sources = newTable[string, seq[string]]()
    defaultAssets.sources["<source directory>"] = @["<glob pattern>"]
    defaultAssets.assets = newTable[string, TableRef[string, string]]()
    defaultAssets.assets["."] = newTable[string, string]()
    let content = pretty(%defaultAssets)
    writeFile(manifest, content)
    echo content
  echo joinPath(getCurrentDir(), manifest)

proc scan(manifest = "assets.json", env = "assets.env") =
  ## Scan for assets in current folder
  let variables = getVariables(env)
  let workingDir = getCurrentDir()
  var assetsJson = getAssetsJson(manifest)
  for dir, _ in assetsJson.assets:
    setCurrentDir(joinPath(workingDir, dir.multiReplace(variables)))
    assetsJson.assets[dir] = newTable[string, string]()
    for _, matches in assetsJson.sources:
      for g in matches:
        for f in walkGlob(g.multiReplace(variables)):
          let hash = toLower($secureHashFile(f))
          let key = f.replace('\\', '/')
          assetsJson.assets[dir][key] = hash
          echo "\"", key, "\": \"", hash, "\""
    setCurrentDir(workingDir)
  setAssetJson(manifest, assetsJson)

proc pull(manifest = "assets.json", env = "assets.env") =
  ## Pull matching assets from sources
  let variables = getVariables(env)
  let assetsJson = getAssetsJson(manifest)
  var workingDir = getCurrentDir()
  var sources: seq[(string, seq[Glob])] = @[]
  for rawSources, globs in assetsJson.sources:
    var parsedGlobs: seq[Glob] = @[]
    for g in globs:
      parsedGlobs.insert(glob(g.multiReplace(variables)))
    for parsedSource in rawSources.multiReplace(variables).split(';'):
      sources.insert((parsedSource, parsedGlobs))
  for dir, assets in assetsJson.assets:
    let assetDir = joinPath(workingDir, dir.multiReplace(variables))
    setCurrentDir(assetDir)
    for asset, hashString in assets:
      block innerLoop:
        let hash = parseSecureHash(hashString)
        let g = "**/" & splitPath(asset).tail
        var filteredSources: seq[string] = @[]
        for (src, globs) in sources:
          block globLoop:
            for g in globs:
              if asset.matches(g):
                filteredSources.insert(src)
                break globLoop
        for src in filteredSources:
          setCurrentDir(src)
          for f in walkGlob(g):
            let currentHash = secureHashFile(f)
            if currentHash == hash:
              setCurrentDir(assetDir)
              let fileA = joinPath(src, f)
              let fileB = joinPath(assetDir, asset)
              createDir(splitPath(fileB).head)
              copyFile(fileA, fileB)
              echo fileA, " --> ", fileB
              break innerLoop
          setCurrentDir(assetDir)
        stderr.writeLine("FIle not found: ", asset, " (", hashString, ")")
    setCurrentDir(workingDir)

when isMainModule:
  import cligen
  dispatchMulti(
    [init],
    [scan],
    [pull],
  )
