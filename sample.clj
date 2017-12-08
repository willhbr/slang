(def defn (macro [name args & body]
                 `(def ~name (fn [~@args] ~@body))))


(defn dec [a] (- a 1))

(defn loop [i func]
  (func)
  (if (<= i 0)
    nil
    (loop (dec i) func)))

(def foo (macro [& a] [~@a]))

(defn print-butts [] (println "butts"))

(println (foo 5 4 5 6))

(print-butts )
