(def defn (macro [name args body]
                 `(def ~name (fn [~@args] ~@body))))

(def unless (macro [condition then]
                   `(if ~condition nil ~then)))

(defn print [a]
  [
   (println "Butt:" a)
   ])

(print (unless false 5))
