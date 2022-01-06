open Core

type t =
  { calories : int
  ; protein : int
  ; fat : int
  ; carbs : int
  }
[@@deriving sexp, bin_io, compare, hash]

type core_macro_type =
  | Protein
  | Fat
  | Carb
[@@deriving sexp, bin_io, compare]

module Requirements = struct
  type 'a requirement =
    | Exactly of 'a
    | At_most of 'a
    | At_least of 'a
    | Between of 'a * 'a
  [@@deriving sexp, bin_io, compare, hash]

  type daily_macro_requirements =
    { calories : int requirement
    ; protein : int requirement
    ; fat : int requirement
    ; carbs : int requirement
    }
  [@@deriving sexp, bin_io, compare, hash]

  type meal_macro_requirements =
    { calories : int requirement
    ; carbs : int requirement
    ; protein : int requirement
    ; fat : int requirement
    }
  [@@deriving sexp, bin_io, compare, hash]

  type t = meal_macro_requirements [@@deriving sexp, bin_io, compare, hash]
end

module Io_meal_macro = Bin_prot_util.With_file_methods (Requirements)
