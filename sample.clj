; (ns Main)

(def defn (macro [n a & b] '(def ~n (fn ~a ~@b))))

(def Person (type first-name last-name))

(println Person)

(let [people [(Person "Will" "Richardson")
              (Person "John" "Smith")]]
  (println people))

(let [string "Hello world"
      doodle [1 2 3]]
  (println (Lengthable.length string))
  (println (Lengthable.length doodle)))
