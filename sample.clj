(def defn (macro [n a & b]
                 `(def ~n (fn [~@a] ~@b))))

(defn func [a] (println a))

(let [func func]
  (println (func func)))
(func 5)

(println (reduce (fn [a b] (+ a b)) [1 2 3]))
