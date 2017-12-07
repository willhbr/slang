(module Main) 

(require others/files/*)

(SomeModule.do-things-with [1 2 3])

(type Thing
      name
      limit
      size)

(Thing "Something" 56 98)
(Thing name: "Something" limit: 12 size: 1)

(defn do-foo [a b & other *stuff]
  ; other is list of arguments
  ; stuff is map of keyword arguments that don't match a or b
  )

; Implement the iterable protocol for the Thing type
(impl Iterable Thing map [it callback]
      (map (:name it) callback))

; Implement many things at once
(impls Iterable Thing
       (map [it callback] ...)
       (reverse [it] ...))

; we can use map on my-thing because it now implements the protocol
(map my-thing println)

; will call the w macro (it must be currently loaded)
#re/foo|bar/
;=> (re "foo|bar")

#nme(Will Richardson)
#nme(Sarang Love Leehan)

#(func 1 2 3)

foobar

/.*?/

%foobar
;=> (gensym foobar)

(defmacro w [input]
  `~(String.split input " "))

; TODO which separators are allowed?
#w<word word word word>
;=> ["word" "word" "word" "word"]


; For shortcut functions?
$(things %1)

; macro methods available:
read
eval
compile-only ; do something only at compile time (like define a binding)
module
require

; useful functions
Iterable.reverse, each, map, filter, reduce, reject
Accessable.get, get?, has-key?, keys, values, assoc

set!, swap! ; and friends?

