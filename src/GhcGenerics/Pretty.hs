{-# LANGUAGE DefaultSignatures #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE TypeOperators #-}

module GhcGenerics.Pretty where

import GHC.Generics

class Pretty a where
  pretty :: a -> String
  pretty = prettyIndent 0

  -- https://ghc.gitlab.haskell.org/ghc/doc/users_guide/exts/default_signatures.html#extension-DefaultSignatures
  prettyIndent :: Int -> a -> String
  default prettyIndent :: (GPretty (Rep a), Generic a) => Int -> a -> String
  prettyIndent n x = gpretty n (from x)

class GPretty f where
  gpretty :: Int -> f p -> String

indent :: Int -> String
indent n = replicate (n * 2) ' '

instance (Datatype d, GPretty f) => GPretty (D1 d f) where
  gpretty n (M1 x) = gpretty n x

instance (Constructor c, GPretty f) => GPretty (C1 c f) where
  gpretty n c@(M1 x) = conName c <> " {\n" <> gpretty (n + 1) x <> "\n" <> indent n <> "}"

instance (GPretty f, Selector s) => GPretty (S1 s f) where
  gpretty n s@(M1 x) =
    case selName s of
      "" -> gpretty n x -- No selector (positional)
      name -> indent n <> name <> " = " <> gpretty n x

instance (GPretty f, GPretty g) => GPretty (f :*: g) where
  gpretty n (f :*: g) = gpretty n f <> "\n" <> gpretty n g

instance (GPretty f, GPretty g) => GPretty (f :+: g) where
  gpretty n (L1 x) = gpretty n x
  gpretty n (R1 x) = gpretty n x

instance (Pretty a) => GPretty (K1 i a) where
  gpretty n (K1 x) = (indent n) <> prettyIndent n x

instance GPretty U1 where
  gpretty _ U1 = ""

instance Pretty Int where
  prettyIndent _ = show

instance Pretty Integer where
  prettyIndent _ = show

instance {-# OVERLAPPING #-} Pretty String where
  prettyIndent _ = show

instance Pretty Bool where
  prettyIndent _ = show

instance (Pretty a) => Pretty (Maybe a) where
  prettyIndent _ Nothing = "Nothing"
  prettyIndent n (Just x) = "Just (\n" <> indent (n + 1) <> prettyIndent (n + 1) x <> "\n" <> indent n <> ")"

instance {-# OVERLAPPABLE #-} (Pretty a) => Pretty [a] where
  prettyIndent n = foldr (\x acc -> acc <> "\n" <> indent (n + 1) <> prettyIndent (n + 1) x <> "\n") ""
