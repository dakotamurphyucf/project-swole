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
  | `UnkownBlock of int
  ]

external tests_teardown : unit -> unit = "ocaml_interop_teardown"
external twice : int -> int = "rust_twice"
external twice_boxed_i64 : int64 -> int64 = "rust_twice_boxed_i64"
external twice_boxed_i32 : int32 -> int32 = "rust_twice_boxed_i32"
external twice_boxed_float : float -> float = "rust_twice_boxed_float"

external twice_unboxed_float
  :  (float[@unboxed])
  -> (float[@unboxed])
  = "" "rust_twice_unboxed_float"

external add_unboxed_floats_noalloc
  :  float
  -> float
  -> float
  = "" "rust_add_unboxed_floats_noalloc"
  [@@unboxed] [@@noalloc]

external increment_bytes : bytes -> int -> bytes = "rust_increment_bytes"
external increment_ints_list : int list -> int list = "rust_increment_ints_list"
external make_tuple : string -> int -> string * int = "rust_make_tuple"
external make_some : string -> string option = "rust_make_some"
external make_ok : int -> (int, string) result = "rust_make_ok"
external make_error : string -> (int, string) result = "rust_make_error"
external sleep_releasing : int -> unit = "rust_sleep_releasing"
external sleep : int -> unit = "rust_sleep"
external string_of_movement : movement -> string = "rust_string_of_movement"

external string_of_polymorphic_movement
  :  movement_polymorphic
  -> string
  = "rust_string_of_polymorphic_movement"

external run_tantiviy : string -> string list = "run_tantiviy"

type tantivy_index

external new_tantivy_index : unit -> tantivy_index = "new_tantivy_index"
external query_tantivy : tantivy_index -> string -> string list = "query_tantivy"
