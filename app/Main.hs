module Main where

import GhcGenerics qualified (run)

main :: IO ()
main = do
    putStrLn "Welcome to Haskell!"
    GhcGenerics.run
