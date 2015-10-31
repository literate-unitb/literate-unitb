{-# LANGUAGE TypeOperators #-}
module Document.Phase.Transient where

    --
    -- Modules
    --
import Document.Pipeline
import Document.Phase as P
import Document.Proof
import Document.Visitor

import Latex.Parser hiding (contents)

import Logic.Expr

import UnitB.AST as AST

    --
    -- Libraries
    --
import           Control.Monad.Trans.Either
import           Control.Monad.Trans.RWS as RWS ( RWS )

import Control.Lens as L hiding ((|>),(<.>),(<|),indices,Context)

import           Data.Map   as M hiding ( map, foldl, (\\) )
import qualified Data.Maybe as MM
import           Data.List as L hiding ( union, insert, inits )
import           Data.List.NonEmpty ( NonEmpty(..) )
import qualified Data.List.NonEmpty as NE

import Utilities.Format
import Utilities.Syntactic

tr_hint :: MachineP2
        -> MachineId
        -> Map String Var
        -> NonEmpty Label
        -> LatexDoc
        -> M TrHint
tr_hint p2 m vs lbls thint = do
    tr@(TrHint wit _)  <- toEither $ tr_hint' p2 m vs lbls thint empty_hint
    evs <- get_events p2 $ NE.toList lbls
    let vs = map (view pIndices p2 !) evs
        err e ind = ( not $ M.null diff
                    , format "A witness is needed for {0} in event '{1}'" 
                        (intercalate "," $ keys diff) e)
            where
                diff = ind `M.difference` wit
    toEither $ error_list 
        $ zipWith err evs vs
    return tr

tr_hint' :: MachineP2
         -> MachineId
         -> Map String Var
         -> NonEmpty Label
         -> LatexDoc
         -> TrHint
         -> RWS LineInfo [Error] () TrHint
tr_hint' p2 _m fv lbls = visit_doc []
        [ ( "\\index"
          , CmdBlock $ \(String x, texExpr) (TrHint ys z) -> do
                evs <- get_events p2 $ NE.toList lbls
                let inds = p2^.pIndices
                vs <- bind_all evs 
                    (format "'{0}' is not an index of '{1}'" x) 
                    (\e -> x `M.lookup` (inds ! e))
                let Var _ t = head vs
                    ind = prime $ Var x t
                    x'  = x ++ "'"
                expr <- hoistEither $ parse_expr' 
                    ((p2^.pMchSynt) `with_vars` insert x' ind fv) 
                        -- { expected_type = Just t }
                    texExpr
                return $ TrHint (insert x (t, expr) ys) z)
        , ( "\\lt"
          , CmdBlock $ \(One prog) (TrHint ys z) -> do
                let msg = "Only one progress property needed for '{0}'"
                toEither $ error_list 
                    [ ( not $ MM.isNothing z
                      , format msg lbls )
                    ]
                return $ TrHint ys (Just prog))
        ]

get_event :: HasMachineP1 phase events => phase events thy -> Label -> M EventId
get_event p2 ev_lbl = do
        let evts = p2^.pEventIds
        bind
            (format "event '{0}' is undeclared" ev_lbl)
            $ ev_lbl `M.lookup` evts

get_events :: MachineP2 -> [Label] -> M [EventId]
get_events p2 ev_lbl = do
            let evts = p2^.pEventIds
            bind_all ev_lbl
                (format "event '{0}' is undeclared")
                $ (`M.lookup` evts)
