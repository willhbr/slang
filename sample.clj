(def defn (macro [name args body]
                 `(def ~name (fn [~@args] ~@body))))

(def unless (macro [condition then]
                   `(if ~condition nil ~then)))

(defn print [a]
  [
   (raise "oh shit")
   ])

(let [foo 6]
  (print (unless false foo)))
