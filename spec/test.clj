(def show-ast (macro [& items] (print_each items)))

(def foo (macro [i] (println i)))

#foo /a b c/
#foo(a b c)
#foo[a b c]
#foo{a: b c: nil}
#foo"Things"

(println "Hello world")
