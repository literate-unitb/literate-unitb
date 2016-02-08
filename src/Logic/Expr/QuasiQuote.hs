{-# LANGUAGE TypeOperators
    ,QuasiQuotes 
    #-}
module Logic.Expr.QuasiQuote
    ( module Logic.Expr.QuasiQuote
    , Name, InternalName ) 
where

    -- Modules
import Document.Proof
import Document.Expression (get_variables'')

import Logic.Expr
import Logic.Expr.Printable
import Logic.Theory

import UnitB.Event
import UnitB.Property

import Theories.Arithmetic

    -- Libraries
import Control.Arrow
import Control.Lens hiding (uncons)
import Control.Monad.State  hiding (lift)

import Data.List
import Data.Maybe
import Data.String.Utils as S

import Language.Haskell.TH hiding (Name)
import Language.Haskell.TH.Quote
import Language.Haskell.TH.Syntax hiding (Name)

import PseudoMacros

import Text.Printf

import Utilities.Instances
import Utilities.Map as M
import Utilities.Syntactic

expr :: QuasiQuoter
expr = QuasiQuoter
    { quoteExp  = \x -> [e| \p -> let loc = $(lift =<< location) in parseExpr loc p $(litE (stringL x)) |]
    , quotePat  = undefined
    , quoteDec  = undefined
    , quoteType = undefined }

act :: QuasiQuoter
act = QuasiQuoter
    { quoteExp  = \x -> [e| \p -> let loc = $(lift =<< location) in parseAction loc p $(litE (stringL x)) |]
    , quotePat  = undefined
    , quoteDec  = undefined
    , quoteType = undefined }

var :: QuasiQuoter
var = QuasiQuoter
    { quoteExp  = \x -> [e| let loc = $(lift =<< location) in parseVarDecl loc $(litE (stringL x)) |]
    , quotePat  = undefined
    , quoteDec  = undefined
    , quoteType = undefined }

carrier :: QuasiQuoter
carrier = QuasiQuoter
    { quoteExp  = parseTypeDecl
    , quotePat  = undefined
    , quoteDec  = undefined
    , quoteType = undefined }

safe :: QuasiQuoter 
safe = QuasiQuoter
    { quoteExp  = \x -> [e| \p -> let loc = $(lift =<< location) in parseSafetyProp loc p $(litE (stringL x)) |]
    , quotePat  = undefined
    , quoteDec  = undefined
    , quoteType = undefined }

parseAction :: Loc -> ParserSetting -> String -> Action
parseAction loc p str = Assign v e
    where
        (rVar,rExpr) = second (intercalate ":=") $ fromMaybe err $ uncons (S.split ":=" str)
        v@(Var _ t)  = parseVar loc p rVar
        e  = parseExpr loc p' rExpr
        p' = p & expected_type .~ Just t
        li = asLI loc
        err = error $ "\n"++ show_err [Error (printf "misshapen assignment: '%s'" str) li]

type Parser a = Loc -> ParserSetting -> String -> a

parseParts :: (a -> b -> c) 
           -> String
           -> String
           -> Parser a -> Parser b -> Parser c
parseParts f sep kind pars0 pars1 loc p str | sep `isInfixOf` str = f v e
                                            | otherwise           = err
    where
        (rVar,rExpr) = second (intercalate sep) $ fromMaybe err $ uncons (S.split sep str)
        v  = pars0 loc p rVar
        e  = pars1 loc p rExpr
        --p' = p & expected_type .~ Just t
        li  = asLI loc
        err = error $ "\n"++ show_err [Error (printf "misshapen %s: '%s'" kind str) li]

parseSafetyProp :: Loc -> ParserSetting -> String -> SafetyProp
parseSafetyProp = parseParts makeSafety "UNLESS" "safety property" parseExpr parseExpr
    where
        makeSafety e0 e1 = Unless [] e0 e1

parseProgressProp :: Loc -> ParserSetting -> String -> ProgressProp
parseProgressProp = parseParts makeProgress "UNLESS" "safety property" parseExpr parseExpr
    where
        makeProgress e0 e1 = LeadsTo [] e0 e1

parseVarDecl :: Loc -> String -> State ParserSetting ()
parseVarDecl loc str = do
        ctx <- gets contextOf
        let e  = fromList $ run $ get_variables'' ctx (asStringLi li str) li
            --e' = M.map f e
            --f (Var n t) = Var (S.replace "'" "@prime" n) t
        decls %= M.union e
    where
        li  = asLI loc
        run = either (error.("\n"++).show_err) id

parseTypeDecl :: String -> ExpQ -- State ParserSetting ()
parseTypeDecl str = do
        --str' <- either (fail . unlines) return 
        --    $ isName $ strip str
        --let texName = str'^.asInternal
        --    s = Sort str' texName 0
        addDependentFile $__FILE__
        let str' = strip str
        [e| do
                let t   = set_type $ make_type s []
                    s   = Sort n (asInternal n) 0
                    n   = fromString'' str'
                sorts %= M.insert n s
                decls %= M.insert n (Var n t) |]

primable :: State ParserSetting () -> State ParserSetting ()
primable cmd = do
    s  <- use decls
    cmd
    s' <- use decls
    primed_vars %= M.union (s' `M.difference` s)

parseVar :: Loc -> ParserSetting -> String -> Var
parseVar loc p str = fromMaybe err $ do
        n' <- isName' n
        M.lookup n' $ p^.decls
    where
        n = strip str
        err = error $ "\n"++ show_err [Error (printf "unknown variables: '%s'" n) li]
        li = asLI loc

parseExpr :: Loc -> ParserSetting -> String -> DispExpr
parseExpr loc p str = either (error.("\n"++).show_err) id
            $ parse_expr p (asStringLi li str)
    where li = asLI loc
    -- either fail lift.

type Ctx = (ParserSetting -> DispExpr) -> DispExpr

--impFunctions :: (String,Theory)
--impFunctions = ("functions",function_theory)

--impSets :: (String,Theory)
--impSets = ("sets",set_theory)

ctxWith :: [Theory] 
        -> State ParserSetting a 
        -> (ParserSetting -> b) -> b
ctxWith xs cmd f = f r
    where
        r = execState cmd (theory_setting $ (empty_theory' "empty") { _extends = 
                symbol_table $ xs ++ [arithmetic,basic_theory] } )

ctx :: State ParserSetting a 
    -> (ParserSetting -> b) -> b
ctx = ctxWith []

instance Lift Var where
    lift = genericLift

instance Lift Expr where
    lift = genericLift

instance Lift Fun where
    lift = genericLift

instance Lift HOQuantifier where
    lift = genericLift

instance Lift QuantifierType where
    lift = genericLift

instance Lift QuantifierWD where
    lift = genericLift

instance Lift Lifting where
    lift = genericLift

instance Lift Value where
    lift = genericLift

instance Lift DispExpr where
    lift = genericLift