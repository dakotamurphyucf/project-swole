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

type tantivy_index

type text_field_option =
  | Text
  | TextAndStored
  | String

type u64_field_option = Indexed | IndexedAndStored
type f64_field_option = Indexed | IndexedAndStored
type facet_field_option = Default

type field =
  | Text of text_field_option
  | U64 of u64_field_option
  | Facet of facet_field_option
  | F64 of f64_field_option

type tantivy_schema

type tantivy_query_parser

external new_tantivy_schema : (string * field) array -> tantivy_schema = "new_tantivy_schema"

external tantivy_index : tantivy_schema -> string -> tantivy_index  = "tantivy_index"

external add_docs_json : tantivy_index -> string  array -> int64  = "add_docs_json"

external create_query_parser: tantivy_index -> string array -> tantivy_query_parser = "create_query_parser"


external _query: tantivy_index -> tantivy_query_parser -> string -> int -> string list  = "query"

let create_query_parser ~index ~default_fields = create_query_parser index default_fields
let query ~index ~parser ~query ~doc_limit = _query index parser query doc_limit

