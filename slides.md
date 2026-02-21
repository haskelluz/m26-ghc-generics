---
marp: true
theme: gaia
paginate: true
author: "Lambdajon"
size: 16:9
---
<style scoped>section{font-size: 25px;}</style>

# Introduction to GHC.Generics

## Goals

- Motivation
- Working with types (**Enumerations**, **Records**)
- Shape of type
- Boilerplate code
- Generic Representations
- Generics, Generics, Generics
- Future learning
- Q&A

Everybody has got to start somewhere.

Scrap your Boilerplate.

---

## Non Goals

Everybody has got to stop somewhere.

We don't compare X to Haskell.

We will not talk about what solutions have been made in other languages.

We don't see the examples in other languages.

---

## Qucik notes:

Inspired by:
> **Scrap Your Boilerplate: A Practical Design Pattern for Generic Programming (Ralf Lämmel, Simon Peyton Jones)**
Some codes from:
> **Thinking with types: Type level programming in haskell (Sandy Magurire)**

---

## Motivation

### **Problem:** Sometimes even copy-pasted code doesn't work

- I copied the code from module X.
- The implementation for the subtype is missing.

---
<style scoped>section{padding-top: 18%;}</style>

> # The compiler can automate what we would otherwise manually copy and paste

---
<style scoped>section{font-size: 25px;}</style>

## Little introduction to types

#### **Numeric Types**

- **`Int`**: Fixed-precision integers (typically 32 or 64 bits, depending on the platform).
- **`Integer`**: Arbitrary-precision integers (can grow as large as memory allows).
- **`Float`**: Single-precision floating-point numbers (32 bits).
- **`Double`**: Double-precision floating-point numbers (64 bits).
- **`Word`**: Unsigned integer types, typically of fixed size (e.g., `Word8`, `Word16`, `Word32`, `Word64`), used for bitwise operations or when only non-negative values are needed.

### **Boolean Type**

- **`Bool`**: A type representing two values, `True` and `False`.

### **Character Type**

- **`Char`**: A single Unicode character (e.g., `'a'`, `'1'`, `'&'`).

---
<style scoped>section{font-size: 25px;}</style>




### **Tuple Types**

- **`(a, b)`**: A tuple of two elements (and similarly for tuples of other sizes, like `(a, b, c)`, etc.). Tuples can hold multiple types, but are fixed in size.


### **List Type**

- **`[a]`**: A list of elements of type `a`.

### **Maybe Type**

- **`Maybe a`**: A type for values that may or may not exist. It is either `Nothing` (no value) or `Just a` (a value of type `a`).

---
<style scoped>section{font-size: 25px;}</style>



### **Unit Type**

- **`()`**: The unit type, often used when there is no meaningful result.

### **IO Type**

- **`IO a`**: A type that encapsulates side-effecting operations (e.g., reading from the console, writing to a file). The type `a` represents the result of the operation.

### **Function Type**

- **`a -> b`**: A function type, representing a function that takes an input of type `a` and returns a result of type `b`.

---
<style scoped>section{font-size: 30px;}</style>

## Working with types

**Enumeration types have multiple variant of constructors**

Color variants.

```haskell

    data Color = Purple | Red | Green | Blue

```

Types can take parametrs

```haskell

    data Tree a = Leaf a | Node (Tree a) (Tree a)

```

---

<style scoped>section{font-size: 25px;}</style>

## Working with types

**Record types**

Similar to tuple (Int, Int, Int)

```haskell

    data RGB = MkRGB Int Int Int

```

Records with named fields

```haskell

    data User = User {name :: String, age :: Int}

```

Single constructor and single field

```haskell

    newtype UserId = UserId Int

```

---

Constructing user

```haskell

    toshmat :: User
    toshmat = User "Toshmat" 20

    eshmat :: User
    eshmat = User{name = "Eshmat", age = 18}

```

---

Let's try applying some functions to the User type

**Oops**
```shell
  λ> eshmat
  <interactive>:5:1: error: [GHC-39999]
      • No instance for ‘Show User’ arising from a use of ‘print’
      • In a stmt of an interactive GHCi command: print it

  λ> eshmat == toshmat 
  <interactive>:6:8: error: [GHC-39999]
      • No instance for ‘Eq User’ arising from a use of ‘==’
      • In the expression: eshmat == toshmat
        In an equation for ‘it’: it = eshmat == toshmat
```

---

**Deriving**
Whith `deriving` feauture Haskell automatically generates type class instances for data types,

```haskell

    data Person = MkPerson {username :: String, email :: String}
      deriving (Show, Eq)
    
    p1 :: Person
    p1 = MkPerson "Eshmat" "eshmat@evil.corp"
    
    p2 :: Person
    p2 = MkPerson "Toshmat" "toshmat@evil.corp"
```

---
<style scoped>section{font-size: 25px;}</style>
**Demonstration**

Showing our data

```shell
    λ> show p1
    MkPerson {username = "Eshmat", email = "eshmat@evil.corp"}

```

Equality of data.
```shell

    λ> p1 == p2
    False
    λ> p1 == p1
    True

```

---

### What would it be like if the show was handwritten?

```haskell
    data User = User { name :: String, age :: Int }

    instance Show User where
      show (User name age) = "User {name = " ++ show name ++ ", age = " ++ show age ++ "}"
```

```shell
  λ> eshmat
  User {name = "Eshmat", age = 18}

```

**I trust you to write an Eq instance!**

---
<style scoped>section{padding-top: 15%;}</style>

**Boilerplate** is ...

- Repetitive code with no interesting logic
- Tedious to write, easy to get wrong
- Breaks every time your data types evolve

**DRY** - Don't repeat yourself. Let the compiler do the work too.

---
<style scoped>section{padding-top: 13%;}</style>

**Can the Either type be used as Maybe?**

`Maybe` and `Either` types.

```haskell
    
    data Maybe a = Just a | Nothing

    data Either a b = Left a | Right b

```

--- 


`Maybe a` is isomorphic to `Either () a`

```haskell
  toEither :: Maybe a -> Either () a
  toEither Nothing = Left ()
  toEither (Just a) = Right a

  fromEither :: Either () a -> Maybe a
  fromEither (Left ()) = Nothing
  fromEither (Right a) = Just a
```

> **Isomorphism is the bridge between types**

**I wonder if it's possible to make a similar function for other types?**

---
<style scoped>section{font-size: 25px;}</style>

### Yes, we can generalize these.

Let's see a simple generalized vesion, Not working yet
```haskell
  
  from :: a -> Representation a x 
  to :: Representation a x -> a 

```
A `Representation` is a structure that represents any shape of type.

This feature already exists in Haskell. `Generic` opens this opportunity for us.

```haskell
  
  class Generic a where
    type Rep a :: Type -> Type
    from :: a -> Rep a x 
    to :: Rep a x -> a 
    -- x is a phantom — it appears in the kind signature but carries no information. Ignore it.
```

---
<style scoped>section{font-size: 30px;}</style>

## Generic Representations

What is representation of haskell types e.g `Bool`?

```shell
  λ>:kind! Rep Bool
  Rep Bool :: * -> *
  = M1
      D
      ('MetaData "Bool" "GHC.Types" "ghc-prim" 'False)
      (M1 C ('MetaCons "False" 'PrefixI 'False) U1
       :+: M1 C ('MetaCons "True" 'PrefixI 'False) U1)
```

- `Bool` has two constructors, so its representation is a sum `:+:`
- Each branch is a constructor with no fields `U1`
- The `M1` wrappers metadata

---

**Let's see it all.**

`V1`    - a type with no constructors (empty, e.g. `Void`)
`U1`    - a constructor with no fields
`K1`    - a single field value (a leaf)
`M1`    - wraps metadata: type name, constructor name, selector name
`(:+:)` - sum: choice between two constructors
`(:*:)` - product: multiple fields within a constructor
`D1`    - metadata at the datatype level   (alias for `M1` `D`)
`C1`    - metadata at the constructor level (alias for `M1` `C`)
`S1`    - metadata at the field level       (alias for `M1` `S`)

So `D1`, `C1`, and `S1` are just `M1` specialized to a particular level — datatype, constructor, and selector respectively.

---
<style scoped>section{padding-top: 10%; font-size: 40px;}</style>

# So, can we implement generic equality for types?

We can use like this ?

```haskell
  
  genericEq eshmat eshmat

```

---
<style scoped>section{padding-top: 18%;}</style>

Sure, let's write the first `GEq` typeclass.

```haskell
  
  class GEq a where
    geq :: a x -> a x -> Bool

```

**And what next?**

---

```haskell
  
  instance GEq U1 where
    geq _ _ = True

  instance GEq V1 where
    geq _ _ = True

  instance (Eq a) => GEq (K1 _1 a) where
    geq (K1 a) (K1 b) = a == b

  instance (GEq a, GEq b) => GEq (a :+: b) where
    geq (L1 a1) (L1 a2) = geq a1 a2
    geq (R1 b1) (R1 b2) = geq b1 b2
    geq _ _ = False

  instance (GEq a, GEq b) => GEq (a :*: b) where
    geq (a1 :*: b1) (a2 :*: b2) = geq a1 a2 && geq b1 b2

  instance (GEq a) => GEq (M1 _x _y a) where
    geq (M1 a1) (M1 a2) = geq a1 a2

```

---

Let's define the `genericEq`

```haskell
  
  genericEq :: (Generic a, GEq (Rep a)) => a -> a -> Bool
  genericEq a b = geq (from a) (from b)

```

It's works!

```shell
  λ> genericEq eshmat eshmat
  True
```

---
## Libraries based on GHC generics

- `aeson` - JSON encoding/decoding
- `binary` - binary serialization
- `generic-lens` - uses GHC Generics to derive lenses
- `uniplate` - simpler generic traversals

From our kitchen

`GPretty` - Simple pretty printing
`FromJson` - Simple json serialization

---

## Future

- If you don't know Haskell, definitely learn it
- `DerivingVia` machinery
- Generic Sum of products - `generic-sop` another approach working with generics

**Nice to have:**

- Meta programming techniques in Haskell
- Template Haskell

---

## Conclusion

- You can derive custom typeclasses with `GHC.Generics`

- Every type has a structure — a sum of constructors, each a product of fields. `GHC.Generics` makes that structure inspectable and programmable

- The boilerplate is not gone — the compiler is writing it

---

# References

- **Scrap Your Boilerplate: A Practical Design Pattern for Generic Programming (Ralf Lämmel, Simon Peyton Jones)**
- **Thinking with types: Type level programming in haskell (Sandy Magurire)**
- **A generic deriving mechanism for Haskell(Jose Pedro Magalhaes,Atze Dijkstra, Andres Löh)**
- **Haskell generics explained (Mark Karpov)**

---

# Q&A
