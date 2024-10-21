import os, strutils

type CliConfig* = object
  configFile*: string
  windowed*: bool
  delaySec*: float

proc parseCliArgs*(): CliConfig =
  result.configFile = getConfigDir() / "boomer" / "config"
  var i = 1
  while i <= paramCount():
    let arg = paramStr(i)
    case arg
    of "-d", "--delay":
      if i + 1 <= paramCount():
        result.delaySec = parseFloat(paramStr(i + 1))
        i += 2
      else:
        quit "No value provided for delay"
    of "-w", "--windowed":
      result.windowed = true
      i += 1
    of "-c", "--config":
      if i + 1 <= paramCount():
        result.configFile = paramStr(i + 1)
        i += 2
      else:
        quit "No value provided for config file"
    else:
      i += 1

proc versionQuit*() =
  const hash = gorgeEx("git rev-parse HEAD")
  quit "boomer-$#" % [if hash.exitCode == 0: hash.output[0 .. 7] else: "unknown"]

proc usageQuit*() =
  quit """Usage: boomer [OPTIONS]
  -d, --delay <seconds: float>  delay execution of the program by provided <seconds>
  -h, --help                    show this help and exit
      --new-config [filepath]   generate a new default config at [filepath]
  -c, --config <filepath>       use config at <filepath>
  -V, --version                 show the current version and exit
  -w, --windowed                windowed mode instead of fullscreen"""