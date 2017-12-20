(def defn (macro [n a & b] '(def ~n (fn ~a ~@b))))

(defn error-fn [a]
  (raise a))

(error-fn "Oh shit son")
