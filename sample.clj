(defn foo [& args ** kw-args]
  (println "Hello!" args kw-args))

(foo 1 3 bar: 4)
