(defn test-args [a b & rest ** others]
  [a b rest others])

(assert (= (test-args 1 2 3 4) [1 2 [3 4] {}]))
(assert (= (test-args 1 2 3 f: 4) [1 2 [3] {f: 4}]))
(assert (= (test-args 1 2 3 f: 4 6 7 8) [1 2 [3 6 7 8] {f: 4}]))
(assert (= (test-args b: 1 a: 2 3 4) [2 1 [3 4] {}]))
(assert (= (test-args c: "Hello" b: 1 a: 2 3 4) [2 1 [3 4] {c: "Hello"}]))

(defmacro test-compile-time []
  (assert (= compile-time? true) "Compile time is true")
  `(assert (= compile-time? false) "Compile time is false"))
 
(test-compile-time)

(defmacro test-expand-splicing [& items]
  [:items ~@items])

(assert (= (test-expand-splicing 1 2 3) [:items 1 2 3]))

(defmacro unless [condition then else]
  `(if ~condition
     ~else
     ~then))
