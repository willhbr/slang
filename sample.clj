(def defn (macro [n a & b] '(def ~n (fn ~a ~@b))))

(def Person (type first-name))

(println #Person{first-name: "Will"})
