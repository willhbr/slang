(def factorial (fn [a] (if (<= a 0)
                   1
                   (* a (factorial (- a 1))))))


(println (factorial 5))
