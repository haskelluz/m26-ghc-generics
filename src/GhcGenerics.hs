module GhcGenerics where

import Data.Text.IO qualified as TIO
import GHC.Generics
import GhcGenerics.JSON.FromJSON
import GhcGenerics.Pretty

data Person = MkPerson
  { name :: !String
  , address :: !String
  , friends :: Maybe [Person]
  }
  deriving (Generic, Show)

deriving anyclass instance FromJSON Person

data Tree a = Leaf a | Node (Tree a) (Tree a)
  deriving (Generic, Show)

deriving anyclass instance Pretty Person
deriving anyclass instance (Pretty a) => Pretty (Tree a)

run :: IO ()
run = do
  pStr <- TIO.readFile "./data/person.json"

  case decode' Person pStr of
    Right (x) -> do
      putStrLn $ pretty $ x
    Left _ -> do print "Failed"
  let tree :: Tree Int = Node (Leaf 1) (Node (Leaf 2) (Leaf 3))
  putStrLn $ pretty tree
