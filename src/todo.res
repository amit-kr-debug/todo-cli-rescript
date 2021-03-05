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
    | Del(option<int>)
    | Done(option<int>)

  let identifyCommand = (~cmd, ~cmdArg): command => {
    switch cmd {
    | "help" => Help
    | "ls" => Ls
    | "add" => Add(cmdArg)
    | "del" => Del(cmdArg->Belt.Option.flatMap(todo_no => todo_no->Belt.Int.fromString))
    | "done" => Done(cmdArg->Belt.Option.flatMap(todo_no => todo_no->Belt.Int.fromString))
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
    if existsSync(filePath) {
      let fileContent = readFileSync(filePath, {encoding: encoding, flag: "r"})
      let todos = Js.String.split(eol, fileContent)
      Js.Array.filter(todo => todo !== "", todos)
    } else {
      []
    }
  }

  let writeTo = (filePath, todos) => {
    let fileContent = Belt.Array.joinWith(todos, eol, todo => todo)
    writeFileSync(filePath, fileContent, {encoding: encoding, flag: "w"})
  }

  let appendTo = (filePath, todo) => {
    let todo = todo ++ eol
    appendFileSync(filePath, todo, {encoding: encoding, flag: "a"})
  }

  let ls = () => {
    let todos = readFrom(todosPath)
    switch todos {
    | [] => Js.log("There are no pending todos!")
    | todos =>
      todos
      ->Belt.Array.reverse
      ->Belt.Array.reduceWithIndex("", (str, todo, index) => {
        str ++ `[${Belt.Int.toString(Belt.Array.length(todos) - index)}] ${todo}${eol}`
      })
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

  let del = (todo_no: option<int>) => {
    switch todo_no {
    | None => Js.log("Error: Missing NUMBER for deleting todo.")
    | Some(todo_no) =>
      if existsSync(todosPath) {
        let todos = readFrom(todosPath)
        if todo_no <= Belt.Array.length(todos) && todo_no > 0 {
          let updatedTodos = Js.Array.filteri((_, index) => index + 1 != todo_no, todos)
          Js.log(`Deleted todo #${Belt.Int.toString(todo_no)}`)
          writeTo(todosPath, updatedTodos)
        } else {
          Js.log(`Error: todo #${Belt.Int.toString(todo_no)} does not exist. Nothing deleted.`)
        }
      }
    }
  }

  let markDone = (todo_no: option<int>) => {
    switch todo_no {
    | None => Js.log(`Error: Missing NUMBER for marking todo as done.`)
    | Some(todo_no) =>
      if existsSync(todosPath) {
        let todos = readFrom(todosPath)
        if todo_no <= Belt.Array.length(todos) && todo_no > 0 {
          let completedTodo = `x ${getToday()} ${todos[todo_no - 1]}`
          appendTo(donePath, completedTodo)
          let updatedTodos = Js.Array.filteri((_, index) => index + 1 != todo_no, todos)
          writeTo(todosPath, updatedTodos)
          Js.log(`Marked todo #${Belt.Int.toString(todo_no)} as done.`)
        } else {
          Js.log(`Error: todo #${Belt.Int.toString(todo_no)} does not exist.`)
        }
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
| Del(todo_no) => Functions.del(todo_no)
| Done(todo_no) => Functions.markDone(todo_no)
}
