let pp_sexp sexp =
  let config = Sexp_pretty.Config.default in
  let config =
    Sexp_pretty.Config.update
      config
      ~interpret_atom_as_sexp:true
      ~drop_comments:false
      ~color:true
      ?new_line_separator:(Some true)
  in
  let fmt = Format.formatter_of_out_channel Caml.stdout in
  let sexp = Sexp_pretty.sexp_to_sexp_or_comment sexp in
  Sexp_pretty.Sexp_with_layout.pp_formatter
    { config with
      atom_coloring = Color_all
    ; color_scheme = [| Blue; Green; Yellow; Red; White |]
    ; singleton_limit = Singleton_limit (Atom_threshold 6, Character_threshold 40)
    }
    fmt
    sexp
;;
