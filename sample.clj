(println (let [foo 1
               binds (*bindings*)]
           (:foo binds)))
