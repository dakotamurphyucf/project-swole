open Core

type t =
  { code : int
  ; met : float
  ; heading : string
  ; activities : string
  }
[@@deriving sexp, bin_io, compare, fields, csv]

let save file rows =
  let rows = List.map rows ~f:row_of_t in
  Csvlib.Csv.save file (csv_header :: rows)
;;

let load file = csv_load file

let show_csv file =
  let items = load file in
  Util.pp_sexp [%sexp (items : t list)]
;;
