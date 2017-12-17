(def defn (macro [n a & b]
                 `(def ~n (fn [~@a] ~@b))))
