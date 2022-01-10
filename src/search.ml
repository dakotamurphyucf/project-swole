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

