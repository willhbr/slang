(ns Main)

(def defn (macro [n a & b]
                 `(def ~n (fn [~@a] ~@b))))

(defn error-fn [] (raise "This is an error! oh no!"))

(defn anon-error-fn []
  (let [func (fn [] (error-fn))]
    (func)))

(defn proxy-fun []
  (error-fn))

(proxy-fun)
