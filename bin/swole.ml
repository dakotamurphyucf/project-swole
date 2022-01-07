open Core
open Swole_lib

let default_dir = "/home/dakota/project-swole/data"

let serving_unit =
  Command.Arg_type.create (fun input ->
      Swole_lib.Ingredient.serving_unit_of_sexp @@ Sexp.of_string input)
;;

let int_requiremnt =
  Command.Arg_type.create (fun input ->
      Swole_lib.Macro.Requirements.requirement_of_sexp Int.t_of_sexp
      @@ Sexp.of_string input)
;;

module Add_ingredient_command = struct
  let command =
    Command.basic
      ~summary:""
      Command.Let_syntax.(
        let%map_open directory =
          flag
            ~aliases:[ "-dir" ]
            "-d"
            (optional_with_default default_dir Filename_unix.arg_type)
            ~doc:"directory Directory where scan data is located"
        and serving =
          flag ~aliases:[ "-serving" ] "-s" (required serving_unit) ~doc:"serving"
        and name = flag ~aliases:[ "-name" ] "-n" (required string) ~doc:"name"
        and calories = flag ~aliases:[ "-cals" ] "-c" (required int) ~doc:"calories"
        and protein =
          flag ~aliases:[ "-protein" ] "-p" (optional_with_default 0 int) ~doc:"protein"
        and fat = flag ~aliases:[ "-fat" ] "-f" (optional_with_default 0 int) ~doc:"fat"
        and carbs =
          flag ~aliases:[ "-carbs" ] "-cb" (optional_with_default 0 int) ~doc:"carbs"
        in
        fun () ->
          let ingr =
            { Swole_lib.Ingredient.name; serving; calories; protein; fat; carbs }
          in
          let ingrs = Ingredient.Io.File.read_all (directory ^ "/ingredients.binio") in
          if List.exists ingrs ~f:(fun i -> Ingredient.compare i ingr = 0)
          then (
            print_endline "ingrediant already exist";
            print_s [%sexp (ingr : Ingredient.t)])
          else (
            Ingredient.Io.File.write_all (directory ^ "/ingredients.binio") [ ingr ];
            print_s [%sexp (ingr :: ingrs : Ingredient.t list)]))
  ;;
end

module List_ingredient_command = struct
  let command =
    Command.basic
      ~summary:"list ingredients"
      Command.Let_syntax.(
        let%map_open directory =
          flag
            ~aliases:[ "-dir" ]
            "-d"
            (optional_with_default default_dir Filename_unix.arg_type)
            ~doc:"directory Directory where ingrediant list is located"
        in
        fun () ->
          let ingrs = Ingredient.Io.File.read_all (directory ^ "/ingredients.binio") in
          print_s [%sexp (ingrs : Ingredient.t list)])
  ;;
end

module Export_ingredients_command = struct
  let command =
    Command.basic
      ~summary:"list ingredients"
      Command.Let_syntax.(
        let%map_open directory =
          flag
            ~aliases:[ "-dir" ]
            "-d"
            (optional_with_default default_dir Filename_unix.arg_type)
            ~doc:"directory Directory where ingrediant list is located"
        and output =
          flag
            ~aliases:[ "-o" ]
            "-output"
            (optional_with_default `Sexp (Arg_type.of_alist_exn [ "sexp", `Sexp ]))
            ~doc:"output format"
        in
        fun () ->
          let ingrs =
            List.sort
              (Ingredient.Io.File.read_all (directory ^ "/ingredients.binio"))
              ~compare:Ingredient.compare
          in
          match output with
          | `Sexp ->
            Sexp.save_hum
              (directory ^ "/ingredients.sexp")
              [%sexp (ingrs : Ingredient.t list)])
  ;;
end

module Generate_protocol_swole_command = struct
  let command =
    Command.basic
      ~summary:"generate_meals_for_protocol_swole"
      Command.Let_syntax.(
        let%map_open directory =
          flag
            ~aliases:[ "-dir" ]
            "-d"
            (optional_with_default default_dir Filename_unix.arg_type)
            ~doc:"directory Directory where ingredients list is located"
        and outdir =
          flag
            ~aliases:[ "-outdir" ]
            "-o"
            (optional_with_default default_dir Filename_unix.arg_type)
            ~doc:"directory Directory where output meals"
        and max =
          flag
            ~aliases:[ "-max" ]
            "-m"
            (optional_with_default 6 int)
            ~doc:"max ingredients"
        in
        fun () ->
          let ingrs = Ingredient.Io.File.read_all (directory ^ "/ingredients.binio") in
          let meals = generate_meals_for_protocol_swole ingrs ~max_ingr:max in
          Sexp.save_hum (outdir ^ "/meals.sexp") [%sexp (meals : Meal.t list)])
  ;;
end

module Generate_meal_command = struct
  open Macro.Requirements

  let command =
    Command.basic
      ~summary:"Generate_meal_command"
      Command.Let_syntax.(
        let%map_open directory =
          flag
            ~aliases:[ "-dir" ]
            "-d"
            (optional_with_default default_dir Filename_unix.arg_type)
            ~doc:"directory Directory where ingredients list is located"
        and outdir =
          flag
            ~aliases:[ "-outdir" ]
            "-o"
            (optional_with_default default_dir Filename_unix.arg_type)
            ~doc:"directory Directory where output meals"
        and max =
          flag
            ~aliases:[ "-max" ]
            "-m"
            (optional_with_default 6 int)
            ~doc:"max ingredients"
        and calories =
          flag ~aliases:[ "-cals" ] "-c" (required int_requiremnt) ~doc:"calories"
        and protein =
          flag
            ~aliases:[ "-protein" ]
            "-p"
            (optional_with_default (At_least 0) int_requiremnt)
            ~doc:"protein"
        and fat =
          flag
            ~aliases:[ "-fat" ]
            "-f"
            (optional_with_default (At_least 0) int_requiremnt)
            ~doc:"fat"
        and carbs =
          flag
            ~aliases:[ "-carbs" ]
            "-cb"
            (optional_with_default (At_least 0) int_requiremnt)
            ~doc:"carbs"
        in
        fun () ->
          let ingrs = Ingredient.Io.File.read_all (directory ^ "/ingredients.binio") in
          let mmr = { calories; protein; carbs; fat } in
          let meals = Meal.generate_meals mmr ingrs ~max_ingr:max in
          Sexp.save_hum (outdir ^ "/meals.sexp") [%sexp (meals : Meal.t list)])
  ;;
end

let command =
  let ing_commands =
    [ "add", Add_ingredient_command.command
    ; "list", List_ingredient_command.command
    ; "export", Export_ingredients_command.command
    ]
  in
  let generate_commands =
    [ "protocol-swole", Generate_protocol_swole_command.command
    ; "generate", Generate_meal_command.command
    ]
  in
  let commands =
    [ "ingredients", Command.group ~summary:"ingredients" ing_commands
    ; "meals", Command.group ~summary:"generate meals" generate_commands
    ]
  in
  Command.group ~summary:"swole" commands
;;

let () = Command_unix.run command
