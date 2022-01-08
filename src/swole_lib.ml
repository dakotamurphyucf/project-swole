open Core
open Macro

(* 
let generate_meals_for_protocol_swole =
  generate_meals
    { Requirements.calories = Between (400, 500)
    ; protein = At_least 38
    ; carbs = At_most 35
    ; fat = At_most 30
    }
;;

*)
module Ingredient = Ingredient
module Macro = Macro
module Meal = Meal
module Util = Util
module Activity = Activity
module Search = Search

open Meal

let generate_meals_for_protocol_swole =
  generate_meals
    { Requirements.calories = Between (300, 500)
    ; protein = At_least 30
    ; carbs = At_most 35
    ; fat = At_most 40
    }
;;

let%expect_test _ =
  let egg =
    { Ingredient.name = "egg"
    ; serving = Unit
    ; calories = 70
    ; protein = 6
    ; fat = 5
    ; carbs = 0
    }
  in
  let cheese =
    { Ingredient.name = "cheese"
    ; serving = Tbl 1
    ; calories = 30
    ; protein = 2
    ; fat = 3
    ; carbs = 0
    }
  in
  let steak =
    { Ingredient.name = "steak"
    ; serving = Oz 3.
    ; calories = 230
    ; protein = 21
    ; fat = 16
    ; carbs = 0
    }
  in
  let ingredients = [ egg; cheese; steak ] in
  let meals = generate_meals_for_protocol_swole ingredients ~max_ingr:6 in
  print_s [%sexp (meals : Meal.t list)];
  [%expect
    {|
  (((macro ((calories 460) (protein 42) (fat 32) (carbs 0)))
    (ingredients
     (((name steak) (serving (Oz 3)) (calories 230) (protein 21) (fat 16)
       (carbs 0))
      ((name steak) (serving (Oz 3)) (calories 230) (protein 21) (fat 16)
       (carbs 0)))))
   ((macro ((calories 370) (protein 33) (fat 26) (carbs 0)))
    (ingredients
     (((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name steak) (serving (Oz 3)) (calories 230) (protein 21) (fat 16)
       (carbs 0)))))
   ((macro ((calories 490) (protein 44) (fat 35) (carbs 0)))
    (ingredients
     (((name cheese) (serving (Tbl 1)) (calories 30) (protein 2) (fat 3)
       (carbs 0))
      ((name steak) (serving (Oz 3)) (calories 230) (protein 21) (fat 16)
       (carbs 0))
      ((name steak) (serving (Oz 3)) (calories 230) (protein 21) (fat 16)
       (carbs 0)))))
   ((macro ((calories 360) (protein 31) (fat 27) (carbs 0)))
    (ingredients
     (((name cheese) (serving (Tbl 1)) (calories 30) (protein 2) (fat 3)
       (carbs 0))
      ((name cheese) (serving (Tbl 1)) (calories 30) (protein 2) (fat 3)
       (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name steak) (serving (Oz 3)) (calories 230) (protein 21) (fat 16)
       (carbs 0)))))
   ((macro ((calories 400) (protein 35) (fat 29) (carbs 0)))
    (ingredients
     (((name cheese) (serving (Tbl 1)) (calories 30) (protein 2) (fat 3)
       (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name steak) (serving (Oz 3)) (calories 230) (protein 21) (fat 16)
       (carbs 0)))))
   ((macro ((calories 440) (protein 39) (fat 31) (carbs 0)))
    (ingredients
     (((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name steak) (serving (Oz 3)) (calories 230) (protein 21) (fat 16)
       (carbs 0)))))
   ((macro ((calories 350) (protein 30) (fat 25) (carbs 0)))
    (ingredients
     (((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0)))))
   ((macro ((calories 470) (protein 41) (fat 34) (carbs 0)))
    (ingredients
     (((name cheese) (serving (Tbl 1)) (calories 30) (protein 2) (fat 3)
       (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name steak) (serving (Oz 3)) (calories 230) (protein 21) (fat 16)
       (carbs 0)))))
   ((macro ((calories 390) (protein 33) (fat 30) (carbs 0)))
    (ingredients
     (((name cheese) (serving (Tbl 1)) (calories 30) (protein 2) (fat 3)
       (carbs 0))
      ((name cheese) (serving (Tbl 1)) (calories 30) (protein 2) (fat 3)
       (carbs 0))
      ((name cheese) (serving (Tbl 1)) (calories 30) (protein 2) (fat 3)
       (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name steak) (serving (Oz 3)) (calories 230) (protein 21) (fat 16)
       (carbs 0)))))
   ((macro ((calories 430) (protein 37) (fat 32) (carbs 0)))
    (ingredients
     (((name cheese) (serving (Tbl 1)) (calories 30) (protein 2) (fat 3)
       (carbs 0))
      ((name cheese) (serving (Tbl 1)) (calories 30) (protein 2) (fat 3)
       (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name steak) (serving (Oz 3)) (calories 230) (protein 21) (fat 16)
       (carbs 0)))))
   ((macro ((calories 420) (protein 35) (fat 33) (carbs 0)))
    (ingredients
     (((name cheese) (serving (Tbl 1)) (calories 30) (protein 2) (fat 3)
       (carbs 0))
      ((name cheese) (serving (Tbl 1)) (calories 30) (protein 2) (fat 3)
       (carbs 0))
      ((name cheese) (serving (Tbl 1)) (calories 30) (protein 2) (fat 3)
       (carbs 0))
      ((name cheese) (serving (Tbl 1)) (calories 30) (protein 2) (fat 3)
       (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name steak) (serving (Oz 3)) (calories 230) (protein 21) (fat 16)
       (carbs 0)))))
   ((macro ((calories 380) (protein 31) (fat 31) (carbs 0)))
    (ingredients
     (((name cheese) (serving (Tbl 1)) (calories 30) (protein 2) (fat 3)
       (carbs 0))
      ((name cheese) (serving (Tbl 1)) (calories 30) (protein 2) (fat 3)
       (carbs 0))
      ((name cheese) (serving (Tbl 1)) (calories 30) (protein 2) (fat 3)
       (carbs 0))
      ((name cheese) (serving (Tbl 1)) (calories 30) (protein 2) (fat 3)
       (carbs 0))
      ((name cheese) (serving (Tbl 1)) (calories 30) (protein 2) (fat 3)
       (carbs 0))
      ((name steak) (serving (Oz 3)) (calories 230) (protein 21) (fat 16)
       (carbs 0)))))
   ((macro ((calories 460) (protein 39) (fat 35) (carbs 0)))
    (ingredients
     (((name cheese) (serving (Tbl 1)) (calories 30) (protein 2) (fat 3)
       (carbs 0))
      ((name cheese) (serving (Tbl 1)) (calories 30) (protein 2) (fat 3)
       (carbs 0))
      ((name cheese) (serving (Tbl 1)) (calories 30) (protein 2) (fat 3)
       (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name steak) (serving (Oz 3)) (calories 230) (protein 21) (fat 16)
       (carbs 0)))))
   ((macro ((calories 500) (protein 43) (fat 37) (carbs 0)))
    (ingredients
     (((name cheese) (serving (Tbl 1)) (calories 30) (protein 2) (fat 3)
       (carbs 0))
      ((name cheese) (serving (Tbl 1)) (calories 30) (protein 2) (fat 3)
       (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name steak) (serving (Oz 3)) (calories 230) (protein 21) (fat 16)
       (carbs 0)))))
   ((macro ((calories 380) (protein 32) (fat 28) (carbs 0)))
    (ingredients
     (((name cheese) (serving (Tbl 1)) (calories 30) (protein 2) (fat 3)
       (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0)))))
   ((macro ((calories 420) (protein 36) (fat 30) (carbs 0)))
    (ingredients
     (((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0)))))
   ((macro ((calories 490) (protein 42) (fat 35) (carbs 0)))
    (ingredients
     (((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0)))))
   ((macro ((calories 450) (protein 38) (fat 33) (carbs 0)))
    (ingredients
     (((name cheese) (serving (Tbl 1)) (calories 30) (protein 2) (fat 3)
       (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0)))))
   ((macro ((calories 410) (protein 34) (fat 31) (carbs 0)))
    (ingredients
     (((name cheese) (serving (Tbl 1)) (calories 30) (protein 2) (fat 3)
       (carbs 0))
      ((name cheese) (serving (Tbl 1)) (calories 30) (protein 2) (fat 3)
       (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0)))))
   ((macro ((calories 370) (protein 30) (fat 29) (carbs 0)))
    (ingredients
     (((name cheese) (serving (Tbl 1)) (calories 30) (protein 2) (fat 3)
       (carbs 0))
      ((name cheese) (serving (Tbl 1)) (calories 30) (protein 2) (fat 3)
       (carbs 0))
      ((name cheese) (serving (Tbl 1)) (calories 30) (protein 2) (fat 3)
       (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0)))))
   ((macro ((calories 410) (protein 33) (fat 34) (carbs 0)))
    (ingredients
     (((name cheese) (serving (Tbl 1)) (calories 30) (protein 2) (fat 3)
       (carbs 0))
      ((name cheese) (serving (Tbl 1)) (calories 30) (protein 2) (fat 3)
       (carbs 0))
      ((name cheese) (serving (Tbl 1)) (calories 30) (protein 2) (fat 3)
       (carbs 0))
      ((name cheese) (serving (Tbl 1)) (calories 30) (protein 2) (fat 3)
       (carbs 0))
      ((name cheese) (serving (Tbl 1)) (calories 30) (protein 2) (fat 3)
       (carbs 0))
      ((name cheese) (serving (Tbl 1)) (calories 30) (protein 2) (fat 3)
       (carbs 0))
      ((name steak) (serving (Oz 3)) (calories 230) (protein 21) (fat 16)
       (carbs 0)))))
   ((macro ((calories 450) (protein 37) (fat 36) (carbs 0)))
    (ingredients
     (((name cheese) (serving (Tbl 1)) (calories 30) (protein 2) (fat 3)
       (carbs 0))
      ((name cheese) (serving (Tbl 1)) (calories 30) (protein 2) (fat 3)
       (carbs 0))
      ((name cheese) (serving (Tbl 1)) (calories 30) (protein 2) (fat 3)
       (carbs 0))
      ((name cheese) (serving (Tbl 1)) (calories 30) (protein 2) (fat 3)
       (carbs 0))
      ((name cheese) (serving (Tbl 1)) (calories 30) (protein 2) (fat 3)
       (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name steak) (serving (Oz 3)) (calories 230) (protein 21) (fat 16)
       (carbs 0)))))
   ((macro ((calories 490) (protein 41) (fat 38) (carbs 0)))
    (ingredients
     (((name cheese) (serving (Tbl 1)) (calories 30) (protein 2) (fat 3)
       (carbs 0))
      ((name cheese) (serving (Tbl 1)) (calories 30) (protein 2) (fat 3)
       (carbs 0))
      ((name cheese) (serving (Tbl 1)) (calories 30) (protein 2) (fat 3)
       (carbs 0))
      ((name cheese) (serving (Tbl 1)) (calories 30) (protein 2) (fat 3)
       (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name egg) (serving Unit) (calories 70) (protein 6) (fat 5) (carbs 0))
      ((name steak) (serving (Oz 3)) (calories 230) (protein 21) (fat 16)
       (carbs 0)))))) |}]
;;
