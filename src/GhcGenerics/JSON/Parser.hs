-- Copyright (c) 2023 Haskell Aeson Contributors
-- Source: https://github.com/haskell/aeson
-- Original code: Data.Aeson.Types.Internal
{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE DerivingVia #-}
{-# LANGUAGE OverloadedStrings #-}

module GhcGenerics.JSON.Parser where

import Data.Char (chr)
import Data.Data (Data)
import Data.List (intercalate)
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Text (Text)
import Data.Text qualified as T
import Data.Typeable (Typeable)
import Data.Vector (Vector)
import Data.Vector qualified as V
import Data.Void (Void)
import GHC.Generics
import Text.Megaparsec
import Text.Megaparsec.Char
import Text.Megaparsec.Char.Lexer qualified as L
import Text.Read (Read (..))

-------------------------------------------------------------------------------
-- JSON key
-------------------------------------------------------------------------------

newtype Key = Key {unKey :: Text}
  deriving (Data, Eq, Ord, Typeable)

rawShow :: Key -> String
rawShow k = "Key " ++ show (T.unpack $ unKey k)

toText :: Key -> Text
toText = unKey

instance Read Key where
  readPrec = fromString <$> readPrec

instance Show Key where
  showsPrec d (Key k) = showsPrec d k

-------------------------------------------------------------------------------
-- JSON Object
-------------------------------------------------------------------------------

type Object = Map Key Value

-------------------------------------------------------------------------------
-- JSON Array
-------------------------------------------------------------------------------

-- | A JSON \"array\" (sequence).
type Array = Vector Value

-- | A JSON value represented as a Haskell value.
data Value
  = Object !Object
  | Array !Array
  | String !Text
  | Bool !Bool
  | Null
  deriving (Data, Eq, Generic, Read, Typeable)

instance Show Value where
  show (Object obj) =
    "{" ++ intercalate ", " (map showKV (Map.toList obj)) ++ "}"
   where
    showKV (k, v) = show (toText k) ++ ": " ++ show v
  show (Array arr) =
    "[" ++ intercalate ", " (map show (V.toList arr)) ++ "]"
  show (String t) = show t
  show (Bool True) = "true"
  show (Bool False) = "false"
  show Null = "null"

-------------------------------------------------------------------------------
-- Parse to Value
-------------------------------------------------------------------------------

type Parser = Parsec Void Text

-- | Whitespace consumer (JSON only has plain whitespace, no comments)
sc :: Parser ()
sc = L.space space1 empty empty

lexeme :: Parser a -> Parser a
lexeme = L.lexeme sc

symbol :: Text -> Parser Text
symbol = L.symbol sc

-- | Parse a JSON value
pValue :: Parser Value
pValue = lexeme pValue'
 where
  pValue' =
    pObject
      <|> pArray
      <|> pString
      <|> pBool
      <|> pNull

pNull :: Parser Value
pNull = Null <$ symbol "null"

pBool :: Parser Value
pBool =
  Bool True
    <$ symbol "true"
      <|> Bool False
    <$ symbol "false"

pString :: Parser Value
pString = String <$> pStringLiteral

-- | Parse a JSON string literal with proper escape handling
pStringLiteral :: Parser Text
pStringLiteral = lexeme $ do
  _ <- char '"'
  cs <- manyTill pStringChar (char '"')
  pure (T.pack cs)

pStringChar :: Parser Char
pStringChar = pEscaped <|> anySingleBut '"'

pEscaped :: Parser Char
pEscaped =
  char '\\'
    *> choice
      [ '"' <$ char '"'
      , '\\' <$ char '\\'
      , '/' <$ char '/'
      , '\b' <$ char 'b'
      , '\f' <$ char 'f'
      , '\n' <$ char 'n'
      , '\r' <$ char 'r'
      , '\t' <$ char 't'
      , pUnicodeEscape
      ]

pUnicodeEscape :: Parser Char
pUnicodeEscape = do
  _ <- char 'u'
  hex <- count 4 hexDigitChar
  pure $ chr (read ("0x" ++ hex))

pArray :: Parser Value
pArray =
  Array . V.fromList
    <$> between (symbol "[") (symbol "]") (pValue `sepBy` symbol ",")

pObject :: Parser Value
pObject =
  Object . Map.fromList
    <$> between (symbol "{") (symbol "}") (pKeyValue `sepBy` symbol ",")

pKeyValue :: Parser (Key, Value)
pKeyValue = do
  k <- Key <$> pStringLiteral
  _ <- symbol ":"
  v <- pValue
  pure (k, v)

-- | Top-level parse function
parseJson :: Text -> Either String Value
parseJson i =
  case parse (sc *> pValue <* eof) "" i of
    Left err -> Left (errorBundlePretty err)
    Right val -> Right val

-------------------------------------------------------------------------------
-- String combinators
-------------------------------------------------------------------------------

fromString :: String -> Key
fromString = Key . T.pack

toString :: Key -> String
toString (Key k) = T.unpack k

-------------------------------------------------------------------------------
-- Helper functions
-------------------------------------------------------------------------------

-- `rawShow` function for `Value`
rawShowValue :: Value -> String
rawShowValue (Object obj) = "Object " ++ rawShowObject obj
rawShowValue (Array arr) = "Array " ++ rawShowArray arr
rawShowValue (String s) = "String " ++ show s
rawShowValue (Bool b) = "Bool " ++ show b
rawShowValue Null = "Null"

-- `rawShow` function for `Object`
rawShowObject :: Object -> String
rawShowObject obj =
  "Map { " ++ concatMap showKeyValue (Map.toList obj) ++ " }"
 where
  showKeyValue (k, v) = rawShow k ++ " -> " ++ rawShowValue v ++ ", "

-- `rawShow` function for `Array`
rawShowArray :: Array -> String
rawShowArray arr =
  "Vector [ " ++ concatMap (\v -> rawShowValue v ++ ", ") (V.toList arr) ++ "]"
