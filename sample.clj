(def defn (macro [n a & b] '(def ~n (fn ~a ~@b))))

(defn map [coll f]
  (Enumerable.reduce coll '()
                     (fn [acc item]
                       (conj acc (f item)))))

(println (map [1 2 3] (fn [a] (* 2 a))))

(println (Enumerable.reduce '(1 2 3) 0 +))
