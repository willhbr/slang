(defmacro print-ast [ast]
  (println ast)
  ast)

(def Person (type first last))

(print-ast (println #Person{first: "Will" last: "Richardson"}))
