(def defn (macro [name args & body]
                 `(def ~name (fn [~@args] ~@body))))


(defn dec [a] (- a 1))

(defn loop [i func]
  (func)
  (if (<= i 0)
    nil
    (loop (dec i) func)))


(defn print-butts [] (println "butts"))

(loop 500 print-butts)
