(def defn (macro [n a & b]
                 `(def ~n (fn [~@a] ~@b))))

(def join (macro [& strings]
                 (reduce (fn [a b] (+ a b)) strings)))

(def joined (join "a" "b" "c"))

(println joined)

(defn func [a] (println a))

(let [func func]
  (println (func func)))
(func 5)

(println (reduce (fn [a b] (+ a b)) [1 2 3]))

(defn foo [a] [~@a])

(println (foo [1 2 3]))
