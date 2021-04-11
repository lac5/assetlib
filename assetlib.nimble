# Package

version       = "0.1.0"
author        = "Larry Costigan <larry.costigan5@gmail.com"
description   = "A simple command line tool for fetching binary files such as images or audio into a project without pushing them to source control such as git."
license       = "MIT"
srcDir        = "src"
binDir        = "bin"
bin           = @["assetlib"]


# Dependencies

requires "nim >= 1.4.2"
requires "cligen"
requires "glob"
requires "dotenv >= 1.1.0"
