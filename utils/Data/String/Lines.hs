{-# LANGUAGE TemplateHaskell,RankNTypes #-}
module Data.String.Lines where

import Control.Applicative
import Control.Arrow
import Control.Lens hiding (elements,(<|))

import Data.Foldable as F (concat)
import Data.List.NonEmpty (NonEmpty(..),fromList,toList,(<|))
import qualified Data.List.NonEmpty as NE
import qualified Data.List as L

import Prelude hiding (lines,unlines)

import qualified Text.PortableLines as PL

import Test.QuickCheck
import Test.QuickCheck.Regression

asLines :: Iso' String (NonEmpty String)
asLines = iso lines' F.concat

traverseLines :: Traversal' String String
traverseLines = asLines . traverse

spanIso :: (a -> Bool) -> Iso [a] [b] ([a],[a]) ([b],[b])
spanIso p = iso (span p) (uncurry (++))

lines :: String -> NonEmpty String
lines xs = fromList $ f ys
    where
        ys = PL.lines $ xs ++ " "
        f [] = []
        f [x] = [init x]
        f (x0:x1:xs) = x0 : f (x1:xs)

lines' :: String -> NonEmpty String
lines' []  = [] :| []
lines' str = let (a, str',b) = breakNewline str
             in if null str' && not b then a :| []
                else a <| lines' str'

    -- Tweak from the version in Text.PortableLines
breakNewline :: String -> (String, String,Bool)
breakNewline []       = ([], [], False)
breakNewline (x : xs) =
    case x of
        '\n' -> ("\n", xs, True)
        '\r' -> over _1 ('\r':) $ case xs of
                         ('\n' : xs') -> ("\n", xs',True)
                         _            -> ("", xs,True)
        _    -> over _1 (x:) $ breakNewline xs
                

unlines :: NonEmpty String -> String
unlines xs = f $ L.unlines $ toList xs
    where
        f [] = []
        f [_] = []
        f (x:xs) = x:f xs

prop_lines_unlines_cancel :: String -> Property
prop_lines_unlines_cancel xs = canonicalizeNewline xs === unlines (lines xs)

canonicalizeNewline :: String -> String
canonicalizeNewline ('\r':'\n':xs) = '\n':canonicalizeNewline xs
canonicalizeNewline ('\r':xs) = '\n':canonicalizeNewline xs
canonicalizeNewline (x:xs) = x:canonicalizeNewline xs
canonicalizeNewline [] = []

prop_unlines_lines_cancel :: Property
prop_unlines_lines_cancel =  forAll gen $
        \xs -> xs === lines (unlines xs)
    where
        gen = fromList <$> listOf1 (listOf $ arbitrary `suchThat` (`notElem` "\r\n"))

prop_lines'_concat_cancel :: String -> Property
prop_lines'_concat_cancel xs = xs === F.concat (lines' xs)

prop_concat_lines'_cancel :: Lines -> Property
prop_concat_lines'_cancel (Lines xs) = xs === lines' (F.concat xs)

prop_concat_lines'_cancel_regression :: Property
prop_concat_lines'_cancel_regression = regression prop_concat_lines'_cancel cases
    where
        cases = 
            [ Lines ("\US\ENQA\r" :| ["_\243U\n","\237`"])
            , Lines ("E\r\n" :| ["\"\185\n","\203\n","\255u\a\r\n","u?'N"])
            , Lines ("\n" :| [""])
            --, Lines ("\r" :| ["\n","7\217\250#\164.\r\n","S\154=9$\GS"])
            ]

newtype Lines = Lines (NonEmpty String)
    deriving (Show)

instance Arbitrary a => Arbitrary (NonEmpty a) where
    arbitrary = (:|) <$> arbitrary <*> arbitrary
    shrink (x :| xs) = map (x :|) $ shrink xs

instance Arbitrary Lines where
    arbitrary = do
        let char  = arbitrary `suchThat` (`notElem` "\n\r")
            line1 = listOf1 char
            line  = listOf char
            line' = L.concat <$> oneof 
                        [ sequence [line,eol]
                        , sequence [line1,return "\n"]]
            eol   = elements ["\r\n","\r"]
            f (x0:x1:xs) 
                | "\r" `L.isSuffixOf` x0 
                    && x1 == "\n" = f (x1:xs)
                | otherwise = x0 : f (x1:xs)
            f x = x
        Lines . fromList . f <$> ((++) <$> listOf line' <*> sequence [line])
    shrink (Lines xs) = filter p $ Lines . f <$> zip [0..] (shrink' xs)
            --Lines . NE.reverse . f <$> zip [0..] (shrink $ NE.reverse xs)
        where
            shrink' xs = NE.reverse . (NE.head xs :|) <$> shrink (NE.tail $ NE.reverse xs)
            f (n,x :| xs) = take n x :| (take' n <$> xs)
            take' n xs = uncurry (++) $ first (take n) $ span (`notElem` "\n\r") xs
            p (Lines xs) = all (`notElem` "\n\r") (NE.head xs') && all (\x -> any (`L.isSuffixOf` x) ["\n","\r\n","\r"]) (NE.tail xs')
                where
                    xs' = NE.reverse xs 

return []

run_tests :: IO Bool
run_tests = $quickCheckAll