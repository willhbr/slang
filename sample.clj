(def defn (macro [n a & b]
                 `(def ~n (fn [~@a] ~@b))))

(defn func [a] (println a))

(let [func 5]
  (println func))
(func 5)
