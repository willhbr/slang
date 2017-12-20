(def defn (macro [n a & b] '(def ~n (fn ~a ~@b))))

(ns Foo
  )

(def bar 5)

(println bar)

(ns Bar)

(println Foo.bar)
