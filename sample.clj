(def defn (macro [name args body]
                 `(def ~name (fn [~@args] ~@body))))

(def unless (macro [condition then]
                   `(if ~condition nil ~then)))

(defn loop [times func]
  [(func)
   (if (<= times 0)
     nil
     (loop (- times 1) func))])

(defn doop-things [arg]
  (
   (+ 1 arg)
   ))

(loop 500 (fn [] (println "Hello")))

(println (doop-things 5))

