/*
Sample JS implementation of Todo CLI that you can attempt to port:
https://gist.github.com/jasim/99c7b54431c64c0502cfe6f677512a87
*/

/* Returns date with the format: 2021-02-04 */
let getToday: unit => string = %raw(`
function() {
  let date = new Date();
  return new Date(date.getTime() - (date.getTimezoneOffset() * 60000))
    .toISOString()
    .split("T")[0];
}
  `)

type fsConfig = {encoding: string, flag: string}

/* https://nodejs.org/api/fs.html#fs_fs_existssync_path */
@bs.module("fs")
external existsSync: string => bool = "existsSync"

/* https://nodejs.org/api/fs.html#fs_fs_readfilesync_path_options */
@bs.module("fs")
external readFileSync: (string, fsConfig) => string = "readFileSync"

/* https://nodejs.org/api/fs.html#fs_fs_writefilesync_file_data_options */
@bs.module("fs")
external appendFileSync: (string, string, fsConfig) => unit = "appendFileSync"

@bs.module("fs")
external writeFileSync: (string, string, fsConfig) => unit = "writeFileSync"

/* https://nodejs.org/api/os.html#os_os_eol */
@bs.module("os")
external eol: string = "EOL"

// for command line arguments
@bs.scope("process") @bs.val
external argv: array<string> = "argv"

let todoPath = "./todo.txt"
let donePath = "./done.txt"
let encoding = "utf8"
/*
NOTE: The code below is provided just to show you how to use the
date and file functions defined above. Remove it to begin your implementation.
*/

module CommandAndArguments = {
  type command =
    | Help
    | Ls

  let identifyCommand = (~cmd: string): command => {
    switch cmd {
    | "help" => Help
    | "ls" => Ls
    | _ => Help
    }
  }
}

module Functions = {
  let help = () => {
    Js.log(`Usage :-
$ ./todo add "todo item"  # Add a new todo
$ ./todo ls               # Show remaining todos
$ ./todo del NUMBER       # Delete a todo
$ ./todo done NUMBER      # Complete a todo
$ ./todo help             # Show usage
$ ./todo report           # Statistics`)
  }

  let ls = () => {
    Js.log("Need to work on it")
  }
}

let cmd = argv->Belt.Array.get(2)->Belt.Option.getWithDefault("help")->Js.String.trim
let cmdArg = argv->Belt.Array.get(3)
let cmd = CommandAndArguments.identifyCommand(~cmd)

switch cmd {
| Help => Functions.help()
| Ls => Functions.ls()
}
