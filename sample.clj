(defn foo []
  (spawn
    (do
      (println (slurp "sample.clj")))))

(spawn (isl))
(foo)
(foo)
(foo)
(foo)
(foo)
(foo)
(foo)


(join)
