open Core

type serving_unit =
  | Unit
  | Tbl of int
  | Oz of float
  | Gm of float
  | Cup of float
[@@deriving sexp, bin_io, compare, hash]

module T = struct
  type t =
    { name : string
    ; serving : serving_unit
    ; calories : int [@compare.ignore]
    ; protein : int [@compare.ignore]
    ; fat : int [@compare.ignore]
    ; carbs : int [@compare.ignore]
    }
  [@@deriving sexp, bin_io, compare, hash]
end

include T
module Io = Bin_prot_util.With_file_methods (T)
