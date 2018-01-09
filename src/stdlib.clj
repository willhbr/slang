(def defn (macro [n a & b] `(def ~n (fn ~a ~@b))))
(def defmacro (macro [n a & b] `(def ~n (macro ~a ~@b))))
(def deftype (macro [n & a] `(def ~n (type ~@a))))
