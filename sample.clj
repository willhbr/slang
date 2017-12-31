(defmacro only-doodle [doodle ** a]
  ~doodle)

(defn bar [a b ** kw-args]
  (println "a:" a "b:" b)
  (println kw-args)
  (println (:foo kw-args)))

(bar 6 1 things: 3 foo: 5)

(println (expand-macros (only-doodle doodle: 5)))
