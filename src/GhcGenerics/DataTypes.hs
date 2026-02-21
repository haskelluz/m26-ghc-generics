{-# LANGUAGE DefaultSignatures #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TypeOperators #-}

module GhcGenerics.DataTypes where

import GHC.Generics
  ( Generic (Rep, from)
  , K1 (K1)
  , M1 (M1)
  , U1
  , V1
  , type (:*:) (..)
  , type (:+:) (..)
  )

-- Simple types
pi :: Double
pi = 3.14

someNum :: Integer
someNum = 42

someStr :: String
someStr = "Hello"

someChar :: Char
someChar = 'X'

-------------------------------------------------------------------------------
-- Enumeration types have multiple variant of constructors
-------------------------------------------------------------------------------

-- Color variants
data Color = Purple | Red | Green | Blue

-- Types can take parametrs
data Tree a = Leaf a | Node (Tree a) (Tree a)

-------------------------------------------------------------------------------
-- Record types
-------------------------------------------------------------------------------

-- Like tuple (Int, Int, Int)
data RGB = MkRGB Int Int Int

-- Records with named fields
data User = User {name :: String, age :: Int} deriving (Generic, Show)

-------------------------------------------------------------------------------
-- Single constructor and single field
-------------------------------------------------------------------------------

newtype UserId = UserId Int
  deriving (Generic)

-------------------------------------------------------------------------------
-- Usage
-------------------------------------------------------------------------------

favoriteColor :: Color
favoriteColor = Purple

sampleTree :: Tree Int
sampleTree = Node (Leaf 1) (Node (Leaf 2) (Leaf 3))

-- (93, 0, 201)
purple :: RGB
purple = MkRGB 93 0 201

eshmat :: User
eshmat = User{name = "Eshmat", age = 18}

toshmat :: User
toshmat = User "Toshmat" 20

uid :: UserId
uid = UserId 1

-------------------------------------------------------------------------------
-- Deriving
-------------------------------------------------------------------------------

data Person = MkPerson
  { username :: String
  , email :: String
  }
  deriving (Eq, Generic, Show)

p1 :: Person
p1 = MkPerson "Eshmat" "eshmat@evil.corp"

-- >>> show p1
-- "MkPerson {username = \"Eshmat\", email = \"eshmat@evil.corp\"}"

p2 :: Person
p2 = MkPerson "Toshmat" "toshmat@evil.corp"

-- >>> p1 == p2
-- False

-------------------------------------------------------------------------------
-- Type shape
-------------------------------------------------------------------------------

-- repBool = Rep Bool

-- >>> :kind! Rep Bool
-- Rep Bool :: * -> *
-- = M1
--     D
--     ('MetaData "Bool" "GHC.Types" "ghc-prim" 'False)
--     (M1 C ('MetaCons "False" 'PrefixI 'False) U1
--      :+: M1 C ('MetaCons "True" 'PrefixI 'False) U1)

-- Example from: "Thinking with types: Type level programming in haskell" Sandy Magurire,
-- page 141, 2018 edition.
class GEq a where
  geq :: a x -> a x -> Bool

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

genericEq :: (GEq (Rep a), Generic a) => a -> a -> Bool
genericEq a b = geq (from a) (from b)

-- >>> genericEq eshmat toshmat
-- False

-- >>> genericEq eshmat eshmat
-- True
