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

let todosPath = "./todo.txt"
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
    | Add(option<string>)

  let identifyCommand = (~cmd, ~cmdArg): command => {
    switch cmd {
    | "help" => Help
    | "ls" => Ls
    | "add" => Add(cmdArg)
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

  let readFrom = filePath => {
    if !existsSync(filePath) {
      []
    } else {
      let fileContent = readFileSync(filePath, {encoding: encoding, flag: "r"})
      let todos = Js.String.split(eol, fileContent)
      Js.Array.filter(todo => todo !== "", todos)
    }
  }

  let writeTo = (filePath, todos) => {
    let fileContent = Belt.Array.joinWith(todos, eol, todo => todo)
    writeFileSync(filePath, fileContent, {encoding: encoding, flag: "w"})
  }

  let appendTo = (filePath, todo) => {
    appendFileSync(filePath, todo, {encoding: encoding, flag: "a"})
  }

  let ls = () => {
    let todos = readFrom(todosPath)
    switch todos {
    | [] => Js.log("There are no pending todos!")
    | todos =>
      todos
      ->Belt.Array.reverse
      ->Belt.Array.reduceWithIndex("", (str, todo, index) =>
        str ++ `[${Belt.Int.toString(Belt.Array.length(todos) - index)}] ${todo} ${eol}`
      )
      ->Js.log
    }
  }

  let add = (todo: option<string>) => {
    switch todo {
    | None => Js.log("Error: Missing todo string. Nothing added!")
    | Some(todo) => {
        appendTo(todosPath, todo)
        Js.log(`Added todo: "${todo}"`)
      }
    }
  }
}

let cmd = argv->Belt.Array.get(2)->Belt.Option.getWithDefault("help")->Js.String.trim
let cmdArg = argv->Belt.Array.get(3)
let cmd = CommandAndArguments.identifyCommand(~cmd, ~cmdArg)

switch cmd {
| Help => Functions.help()
| Ls => Functions.ls()
| Add(todo) => Functions.add(todo)
}
