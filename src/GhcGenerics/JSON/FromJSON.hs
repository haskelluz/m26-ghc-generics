{-# LANGUAGE DefaultSignatures #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE RequiredTypeArguments #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE UndecidableInstances #-}

module GhcGenerics.JSON.FromJSON where

import Control.Applicative (Alternative (..))
import Data.Map.Strict qualified as Map
import Data.Text (Text)
import Data.Text qualified as T
import Data.Vector qualified as V
import GHC.Generics
import GhcGenerics.JSON.Parser (Key (..), Object, Value (..), parseJson)

-------------------------------------------------------------------------------
-- Parser
-------------------------------------------------------------------------------

newtype Parser a = Parser {runParser :: Either String a}
  deriving stock (Show)
  deriving newtype (Applicative, Functor, Monad)

-- Alternative lets us write "try left, fall back to right" cleanly
instance Alternative Parser where
  empty = Parser (Left "empty")
  Parser (Left _) <|> p = p
  p <|> _ = p

parseFail :: String -> Parser a
parseFail = Parser . Left

-------------------------------------------------------------------------------
-- FromJSON
-------------------------------------------------------------------------------

class FromJSON a where
  parseJSON :: Value -> Parser a
  default parseJSON :: (GFromJSON (Rep a), Generic a) => Value -> Parser a
  parseJSON v = to <$> gparseJSON v

-------------------------------------------------------------------------------
-- Generic machinery
-------------------------------------------------------------------------------

class GFromJSON f where
  gparseJSON :: Value -> Parser (f p)

-- V1: empty type (no constructors, e.g. Void)
instance GFromJSON V1 where
  gparseJSON _ = parseFail "Cannot parse empty type"

-- U1: constructor with no fields
instance GFromJSON U1 where
  gparseJSON _ = pure U1

-- K1: single field value (leaf) — delegates to FromJSON
instance (FromJSON a) => GFromJSON (K1 i a) where
  gparseJSON v = K1 <$> parseJSON v

-- D1: metadata at the datatype level
instance (GFromJSON f) => GFromJSON (D1 d f) where
  gparseJSON v = M1 <$> gparseJSON v

-- C1: metadata at the constructor level
instance (GFromJSON f) => GFromJSON (C1 c f) where
  gparseJSON v = M1 <$> gparseJSON v

-- S1: metadata at the field level — looks up field by selName
instance (GFromJSON f, Selector s) => GFromJSON (S1 s f) where
  gparseJSON (Object obj) =
    let key = Key . T.pack $ selName (undefined :: S1 s f p)
     in case Map.lookup key obj of
          Nothing -> parseFail $ "Missing field: " <> T.unpack (unKey key)
          Just val -> M1 <$> gparseJSON val
  gparseJSON _ = parseFail "Expected object"

-- (:+:): sum — try left constructor, fall back to right
instance (GFromJSON f, GFromJSON g) => GFromJSON (f :+: g) where
  gparseJSON v = L1 <$> gparseJSON v <|> R1 <$> gparseJSON v

-- (:*:): product — parse both fields against the same object
instance (GFromJSON f, GFromJSON g) => GFromJSON (f :*: g) where
  gparseJSON v = (:*:) <$> gparseJSON v <*> gparseJSON v

-------------------------------------------------------------------------------
-- Primitive instances
-------------------------------------------------------------------------------

instance FromJSON Value where parseJSON = pure

instance FromJSON Text where
  parseJSON (String t) = pure t
  parseJSON _ = parseFail "Expected string"

instance FromJSON Bool where
  parseJSON (Bool b) = pure b
  parseJSON _ = parseFail "Expected boolean"

instance (FromJSON a) => FromJSON (Maybe a) where
  parseJSON Null = pure Nothing
  parseJSON v = Just <$> parseJSON v

instance {-# OVERLAPPING #-} FromJSON String where
  parseJSON (String t) = pure (T.unpack t)
  parseJSON _ = parseFail "Expected string"

instance {-# OVERLAPPABLE #-} (FromJSON a) => FromJSON [a] where
  parseJSON (Array arr) = traverse parseJSON (V.toList arr)
  parseJSON _ = parseFail "Expected array"

decode' :: forall a -> (FromJSON a) => Text -> Either String a
decode' tyA inp = case parseJson inp of
  Left err -> Left err
  Right (val) -> (runParser @tyA (parseJSON val))

decode :: (FromJSON a) => Text -> Either String a
decode input = case parseJson input of
  Left err -> Left err
  Right val -> runParser (parseJSON val)
