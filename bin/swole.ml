open Core
open Swole_lib


type movement =
  | Step of int
  | Expand of (int * int)
  | RotateLeft
  | RotateRight
  | Unknown
  | UnkownBlock of int

type movement_polymorphic =
  [ `Step of int
  | `Expand of int * int
  | `RotateLeft
  | `RotateRight
  | `Unknown
  | `UnkownBlock of int ]

module Rust = struct
  external tests_teardown : unit -> unit = "ocaml_interop_teardown"

  external twice : int -> int = "rust_twice"

  external twice_boxed_i64 : int64 -> int64 = "rust_twice_boxed_i64"

  external twice_boxed_i32 : int32 -> int32 = "rust_twice_boxed_i32"

  external twice_boxed_float : float -> float = "rust_twice_boxed_float"

  external twice_unboxed_float : (float[@unboxed]) -> (float[@unboxed])
    = "" "rust_twice_unboxed_float"

  external add_unboxed_floats_noalloc : float -> float -> float
    = "" "rust_add_unboxed_floats_noalloc"
    [@@unboxed] [@@noalloc]

  external increment_bytes : bytes -> int -> bytes = "rust_increment_bytes"

  external increment_ints_list : int list -> int list
    = "rust_increment_ints_list"

  external make_tuple : string -> int -> string * int = "rust_make_tuple"

  external make_some : string -> string option = "rust_make_some"

  external make_ok : int -> (int, string) result = "rust_make_ok"

  external make_error : string -> (int, string) result = "rust_make_error"

  external sleep_releasing : int -> unit = "rust_sleep_releasing"

  external sleep : int -> unit = "rust_sleep"

  external string_of_movement : movement -> string = "rust_string_of_movement"

  external string_of_polymorphic_movement : movement_polymorphic -> string
    = "rust_string_of_polymorphic_movement"

  external run_tantiviy: string -> string list = "run_tantiviy"
end
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

let list_all_colors () : unit =
  Ocolor_config.set_color_capability Color24;
  List.iter
    ~f:(fun (name, (r24, g24, b24)) ->
      Ocolor_format.printf
        "%a%s%s 0x%02X%02X%02X   %03d, %03d, %03d%a\n"
        Ocolor_format.pp_open_style
        (Fg (C24 { r24; g24; b24 }))
        name
        (String.make (max 0 (30 - String.length name)) ' ')
        r24
        g24
        b24
        r24
        g24
        b24
        Ocolor_format.pp_close_style
        ())
    Ocolor_x11.available_colors
;;

let rec prompt_for_param : type a. ?default:a -> string -> (string -> a) -> a =
 fun ?default name of_t ->
  let flush () = Ocolor_format.pp_print_flush Ocolor_format.std_formatter () in
  Ocolor_format.printf
    "@{<yellow1;bold;>enter @{<blue;bold>%s@}@{<red;bold> -> @}@}%!"
    name;
  flush ();
  match In_channel.input_line In_channel.stdin with
  | None ->
    (match default with
    | None ->
      Ocolor_format.printf "@{<red>please provide value @}";
      flush ();
      prompt_for_param name of_t
    | Some x -> x)
  | Some line ->
    (match String.length line with
    | 0 ->
      (match default with
      | None ->
        Ocolor_format.printf "@{<red>please provide value @}";
        flush ();
        prompt_for_param name of_t
      | Some x -> x)
    | _ -> of_t line)
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
          flag ~aliases:[ "-serving" ] "-s" (optional serving_unit) ~doc:"serving"
        and name = flag ~aliases:[ "-name" ] "-n" (optional string) ~doc:"name"
        and calories = flag ~aliases:[ "-cals" ] "-c" (optional int) ~doc:"calories"
        and protein = flag ~aliases:[ "-protein" ] "-p" (optional int) ~doc:"protein"
        and fat = flag ~aliases:[ "-fat" ] "-f" (optional int) ~doc:"fat"
        and carbs = flag ~aliases:[ "-carbs" ] "-cb" (optional int) ~doc:"carbs" in
        fun () ->
          let serving =
            match serving with
            | Some x -> x
            | None ->
              prompt_for_param "serving" (fun input ->
                  Swole_lib.Ingredient.serving_unit_of_sexp @@ Sexp.of_string input)
          in
          let name =
            match name with
            | Some x -> x
            | None -> prompt_for_param "name" (fun s -> s)
          in
          let calories =
            match calories with
            | Some x -> x
            | None -> prompt_for_param "calories" Int.of_string
          in
          let protein =
            match protein with
            | Some x -> x
            | None -> prompt_for_param ~default:0 "protein defaults to 0" Int.of_string
          in
          let fat =
            match fat with
            | Some x -> x
            | None -> prompt_for_param ~default:0 "fat defaults to 0" Int.of_string
          in
          let carbs =
            match carbs with
            | Some x -> x
            | None -> prompt_for_param ~default:0 "carbs defaults to 0" Int.of_string
          in
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
            Util.pp_sexp [%sexp (ingr :: ingrs : Ingredient.t list)]))
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
          Util.pp_sexp [%sexp (ingrs : Ingredient.t list)])
  ;;
end

module List_activities_command = struct
  let default_dir = "/home/dakota/project-swole"
  let command =
    Command.basic
      ~summary:"list activities"
      Command.Let_syntax.(
        let%map_open directory =
          flag
            ~aliases:[ "-dir" ]
            "-d"
            (optional_with_default default_dir Filename_unix.arg_type)
            ~doc:"directory Directory where ingrediant list is located"
        in
        fun () -> Activity.show_csv (directory ^ "/activity.csv"); 
          let docs = Rust.run_tantiviy " river the golden foothill " in
          List.iter docs ~f:print_endline)
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
        and max = flag ~aliases:[ "-max" ] "-m" (optional int) ~doc:"max ingredients"
        and calories =
          flag ~aliases:[ "-cals" ] "-c" (optional int_requiremnt) ~doc:"calories"
        and protein =
          flag ~aliases:[ "-protein" ] "-p" (optional int_requiremnt) ~doc:"protein"
        and fat = flag ~aliases:[ "-fat" ] "-f" (optional int_requiremnt) ~doc:"fat"
        and carbs =
          flag ~aliases:[ "-carbs" ] "-cb" (optional int_requiremnt) ~doc:"carbs"
        in
        fun () ->
          let f input =
            Swole_lib.Macro.Requirements.requirement_of_sexp Int.t_of_sexp
            @@ Sexp.of_string input
          in
          let calories =
            match calories with
            | Some x -> x
            | None -> prompt_for_param "calories" f
          in
          let protein =
            match protein with
            | Some x -> x
            | None ->
              prompt_for_param ~default:(At_least 0) "protein defaults to (At_least 0)" f
          in
          let fat =
            match fat with
            | Some x -> x
            | None ->
              prompt_for_param ~default:(At_least 0) "fat defaults to (At_least 0)" f
          in
          let carbs =
            match carbs with
            | Some x -> x
            | None ->
              prompt_for_param ~default:(At_least 0) "carbs defaults to (At_least 0)" f
          in
          let max =
            match max with
            | Some x -> x
            | None -> prompt_for_param ~default:5 "max defaults to 5" Int.of_string
          in
          let ingrs = Ingredient.Io.File.read_all (directory ^ "/ingredients.binio") in
          let mmr = { calories; protein; carbs; fat } in
          let meals = Meal.generate_meals mmr ingrs ~max_ingr:max in
          Sexp.save_hum (outdir ^ "/meals.sexp") [%sexp (meals : Meal.t list)];
          Util.pp_sexp [%sexp (meals : Meal.t list)])
  ;;
end

let command =
  let ing_commands =
    [ "add", Add_ingredient_command.command
    ; "list", List_ingredient_command.command
    ; "export", Export_ingredients_command.command
    ]
  in
  let activity_commands = [ "list", List_activities_command.command ] in
  let generate_commands =
    [ "protocol-swole", Generate_protocol_swole_command.command
    ; "generate", Generate_meal_command.command
    ]
  in
  let commands =
    [ "ingredients", Command.group ~summary:"ingredients" ing_commands
    ; "meals", Command.group ~summary:"generate meals" generate_commands
    ; "activity", Command.group ~summary:"activity" activity_commands
    ]
  in
  Command.group ~summary:"swole" commands
;;

let () = Command_unix.run command
