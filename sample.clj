(def defn (macro [n a & b] '(def ~n (fn ~a ~@b))))

(def dood (macro []
                 (raise "compile time error!")
                 5))

(dood)
