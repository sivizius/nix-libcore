/*
  derivation:
    derivation
    derivationStrict
    __parseDrvName
    fetchTree
    __unsafeDiscardOutputDependency

  expression:
    __toJSON
    __toXML
    __seq
    __deepSeq
    fetch:
      __fromJSON
      fromTOML

  lambda:
    __isFunction
    __functionArgs

  list:
    __all
    __any
    __elemAt
    __head
    __tail
    __isList
    map
    __foldl'
    __elem
    __filter
    __length
    __genList
    __sort
    __partition
    __concatLists
    __concatMap

  attrs:
    __mapAttrs
    __attrNames
    __isAttrs
    __intersectAttrs
    __listToAttrs
    __hasAttr
    __attrValues
    __getAttr
    removeAttrs
    __catAttrs
    __unsafeGetAttrPos

  number:
    __add
    __sub
    __div
    __mul
    __lessThan
    int:
      __isInt
      __bitAnd
      __bitOr
      __bitXor
    float:
      __ceil
      __floor
      __isFloat

  path:
    __hashFile
    __toFile
    __toPath
    __isPath
    baseNameOf
    dirOf
    __findFile
    __readDir
    __pathExists
    __readFile
    placeholder
    __path
    __filterSource

  string:
    __isString
    __split
    __match
    __hashString
    __substring
    toString
    __stringLength
    __concatStringsSep
    __replaceStrings

  type:
    __typeOf

  debug:
    __trace

  panic:
    abort
    throw
    __addErrorContext

  context:
    __getContext
    __appendContext
    __unsafeDiscardStringContext
    __hasContext



__genericClosure

*/