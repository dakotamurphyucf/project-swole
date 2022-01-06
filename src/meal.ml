open Core
open Macro

type t =
  { macro : Macro.t
  ; ingredients : Ingredient.t list
  }
[@@deriving sexp, bin_io, compare, hash]

module Ingredient_tbl = struct
  module T = struct
    type t = Ingredient.t list [@@deriving sexp, bin_io, compare, hash]
  end

  include T
  include Comparable.Make (T)
end

let add_ingr ingr ~meal =
  let p_macro = meal.macro in
  let macro =
    { fat = p_macro.fat + ingr.fat
    ; calories = p_macro.calories + ingr.Ingredient.calories
    ; protein = p_macro.protein + ingr.protein
    ; carbs = p_macro.carbs + ingr.carbs
    }
  in
  { macro
  ; ingredients = List.sort (ingr :: meal.ingredients) ~compare:Ingredient.compare
  }
;;

let meets_mmr ~mmr meal =
  let meets v = function
    | Requirements.Exactly r -> r = v
    | At_most r -> v <= r
    | At_least r -> v >= r
    | Between (r1, r2) -> r1 <= v && v <= r2
  in
  let meets_calories = meets meal.macro.calories mmr.Requirements.calories in
  let meets_fat = meets meal.macro.fat mmr.Requirements.fat in
  let meets_protein = meets meal.macro.protein mmr.Requirements.protein in
  let meets_carbs = meets meal.macro.carbs mmr.Requirements.carbs in
  meets_calories && meets_fat && meets_protein && meets_carbs
;;

let empty_meal =
  { macro = { calories = 0; protein = 0; fat = 0; carbs = 0 }; ingredients = [] }
;;

let generate_meals mmr ingredients ~max_ingr =
  let rec aux ?(index = 0) cookbook meals  =
    match index = max_ingr with
    | true -> cookbook
    | false ->
      let seen = Set.empty (module Ingredient_tbl) in
      let _, new_meal_candidates =
        List.fold ~init:(seen, []) ~f:(fun (seen, acc) meal ->
            if Set.mem seen meal.ingredients
            then seen, acc
            else Set.add seen meal.ingredients, meal :: acc)
        @@ List.concat
        @@ List.map meals ~f:(fun meal ->
               List.map ingredients ~f:(fun ingr -> add_ingr ingr ~meal))
      in
      let valid_meals =
        List.filter new_meal_candidates ~f:(meets_mmr ~mmr )
      in
      aux
        ~index:(index + 1)
        (cookbook @ valid_meals)
        new_meal_candidates
  in
  let meals = List.map ingredients ~f:(add_ingr ~meal:empty_meal) in
  aux [] meals
;;
