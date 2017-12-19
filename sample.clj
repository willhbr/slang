; (ns Main)

(def defn (macro [n a & b] '(def ~n (fn ~a ~@b))))

(def Person (type first-name last-name))

(println Person)

(let [people [#Person{first-name: "Will" last-name: "Richardson"}
              #Person{first-name: "John" last-name: "Smith"}]]
  (println people))

(let [string "Hello world"
      doodle [1 2 3]]
  (println (Lengthable.length string))
  (println (Lengthable.length doodle)))
