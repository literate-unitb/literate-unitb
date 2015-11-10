{-# LANGUAGE OverloadedStrings
    , QuasiQuotes
    , ConstraintKinds
    #-}
module Document.Phase.Test where

    --
    -- Modules
    --
import Document.Machine
import Document.Phase
import Document.Phase.Declarations
import Document.Phase.Expressions
import Document.Phase.Proofs
import Document.Phase.Structures
import Document.Pipeline
import Document.Proof
import Document.Refinement
import Document.Scope
import Document.ExprScope hiding (var)
import Document.VarScope  hiding (var)

import Latex.Monad

import Logic.Expr.QuasiQuote
import Logic.Theory

import Theories.Arithmetic
import Theories.SetTheory

import UnitB.Expr hiding (decl)
import Tests.UnitTest

import UnitB.AST as AST

    --
    -- Libraries
    --
import Control.Arrow
import Control.Lens hiding ((<.>),(.=))
import Control.Monad
import Control.Monad.Reader
import Control.Monad.State
import Control.Monad.Writer

import Data.Default
import Data.List as L
import Data.List.NonEmpty as NE
import Data.Map  as M
import Data.Maybe

import Test.QuickCheck

import Utilities.BipartiteGraph as G
import Utilities.Existential
import Utilities.Lens
import Utilities.Syntactic

newtype MapSyntax k a b = MapSyntax (Writer [(k,a)] b)
    deriving (Functor,Applicative,Monad)

(##) :: k -> a -> MapSyntax k a ()
x ## y = MapSyntax (tell [(x,y)])

runMapWith :: (Ord k) 
           => (a -> a -> a) 
           -> MapSyntax k a b 
           -> Map k a
runMapWith f (MapSyntax cmd) = M.fromListWith f $ execWriter cmd

runMap :: (Ord k, Scope a) 
       => MapSyntax k a b 
       -> Map k a
runMap = runMapWith merge_scopes
runMap' :: (Ord k) 
        => MapSyntax k a b 
        -> Map k a
runMap' = runMapWith const

test_case :: TestCase
test_case = test

test :: TestCase
test = $(makeTestSuite "Unit tests for the parser")

name0 :: TestName
name0 = testName "test 0, phase 1 (structure), create object" 

case0 :: IO (MTable MachineP1)
case0 = do
    let ms = M.fromList [(MId "m0",()),(MId "m1",())]
        p0 = mapWithKey (const . MachineP0 ms) ms
        thy = M.fromList 
                [ (MId "m0", M.fromList $ ("arithmetic",arithmetic):thy2) 
                , (MId "m1", M.fromList $ ("sets", set_theory):thy2) ]
        thy2 = [("basic", basic_theory),("arithmetic",arithmetic)]
        s0 = Sort "S0" "S0" 0
        s0' = make_type s0 [] 
        se new_type = zlift (set_type new_type) ztrue
        s1 = Sort "\\S1" "sl@S1" 0
        s1' = make_type s1 [] 
        li = LI "file.ext" 1 1
        sorts = M.fromList
                [ (MId "m0",M.singleton "S0" s0) 
                , (MId "m1",M.fromList [("S0",s0),("\\S1",s1)])]
        f th = M.unions $ L.map (view AST.types) $ M.elems th
        allSorts = M.intersectionWith (\ts th -> ts `M.union` f th) sorts thy
        pdef  = M.fromList
                [ (MId "m0",[("S0",(Def [] "S0" [] (set_type s0') (se s0'),Local,li))]) 
                , (MId "m1",[("\\S1",(Def [] "sl@S1" [] (set_type s1') (se s1'),Local,li))])]
        evts = M.fromList 
                [ (MId "m0",evts0)
                , (MId "m1",evts1) ]
        skipEvt = Left SkipEvent
        evts0 = fromJust $ makeGraph $ do
            ae0  <- newRightVertex (Right "ae0") ()
            ae1a <- newRightVertex (Right "ae1a") ()
            ae1b <- newRightVertex (Right "ae1b") ()
            cskip <- newRightVertex skipEvt ()
            askip <- newLeftVertex skipEvt ()
            forM_ [ae0,ae1a,ae1b,cskip] $ newEdge askip
        evts1 = fromJust $ makeGraph $ do
            ae0 <- newLeftVertex (Right "ae0") ()
            ae1a <- newLeftVertex (Right "ae1a") ()
            ae1b <- newLeftVertex (Right "ae1b") ()
            askip <- newLeftVertex skipEvt ()
            ce0a <- newRightVertex (Right "ce0a") ()
            ce0b <- newRightVertex (Right "ce0b") ()
            ce1 <- newRightVertex (Right "ce1") ()
            ce2 <- newRightVertex (Right "ce2") ()
            cskip <- newRightVertex skipEvt ()
            newEdge ae0 ce0a
            newEdge ae0 ce0b
            newEdge ae1a ce1
            newEdge ae1b ce1
            newEdge askip ce2
            newEdge askip cskip
    return $ make_phase1 <$> p0 <.> thy 
                         <.> sorts <.> allSorts 
                         <.> pdef <.> evts

result0 :: MTable MachineP1
result0 = M.fromList 
        [ (MId "m0",m0) 
        , (MId "m1",m1) ]
    where
        ms = M.fromList 
            [ (MId "m0",()) 
            , (MId "m1",()) ]
        skipEvt = Left SkipEvent
        newAEvent eid = newLeftVertex  (Right eid) (EventP1 $ Right eid)
        newCEvent eid = newRightVertex (Right eid) (EventP1 $ Right eid)
        abstractSkip = newLeftVertex  skipEvt (EventP1 skipEvt)
        concreteSkip = newRightVertex skipEvt (EventP1 skipEvt)

        evts0 = fromJust $ makeGraph $ do
            ae0 <- newCEvent "ae0"
            ae1a <- newCEvent "ae1a"
            ae1b <- newCEvent "ae1b"
            cskip <- concreteSkip
            askip <- abstractSkip
            forM_ [ae0,ae1a,ae1b,cskip] $ newEdge askip
        evts1 = fromJust $ makeGraph $ do
            ae0 <- newAEvent "ae0"
            ae1a <- newAEvent "ae1a"
            ae1b <- newAEvent "ae1b"
            askip <- abstractSkip
            ce0a <- newCEvent "ce0a"
            ce0b <- newCEvent "ce0b"
            ce1 <- newCEvent "ce1"
            ce2 <- newCEvent "ce2"
            cskip <- concreteSkip
            newEdge ae0 ce0a
            newEdge ae0 ce0b
            newEdge ae1a ce1
            newEdge ae1b ce1
            newEdge askip ce2
            newEdge askip cskip
        p0 = MachineP0 ms . MId
        tp0 = TheoryP0 ()
        m0 = MachineP1 (p0 "m0") evts0 (TheoryP1 tp0 thy0 sorts0 allSorts0 pdef0)
        m1 = MachineP1 (p0 "m1") evts1 (TheoryP1 tp0 thy1 sorts1 allSorts1 pdef1)
        s0 = Sort "S0" "S0" 0
        s0' = make_type s0 [] 
        se new_type = zlift (set_type new_type) ztrue
        s1 = Sort "\\S1" "sl@S1" 0
        s1' = make_type s1 [] 
        sorts0 = M.singleton "S0" s0
        sorts1 = M.singleton "\\S1" s1 `M.union` sorts0
        f th = M.unions $ L.map (view AST.types) $ M.elems th
        allSorts0 = sorts0 `M.union` f thy0
        allSorts1 = sorts1 `M.union` f thy1
        pdef0  = [("S0",(Def [] "S0" [] (set_type s0') (se s0'),Local,li))]
        pdef1  = [("\\S1",(Def [] "sl@S1" [] (set_type s1') (se s1'),Local,li))]
        thy0 = M.singleton "arithmetic" arithmetic `M.union` thy2
        thy1 = M.singleton "sets" set_theory `M.union` thy2
        thy2 = M.fromList [("basic",basic_theory),("arithmetic",arithmetic)]
        li = LI "file.ext" 1 1

name1 :: TestName
name1 = testName "test 1, phase 1, parsing"

case1 :: IO (Either [Error] SystemP1)
case1 = return $ runPipeline' ms cs () $ run_phase0_blocks >>> run_phase1_types
    where
        ms = M.map (:[]) $ M.fromList 
                [ ("m0",makeLatex "file.ext" $ do       
                            command "newset" [text "S0"]                 
                            command "newevent" [text "ae0"]
                            command "newevent" [text "ae1a"]
                            command "newevent" [text "ae1b"]
                        ) 
                    -- what if we split or merge non-existant events?
                , ("m1",makeLatex "file.ext" $ do
                            command "newset" [text "\\S1"]                 
                            command "refines" [text "m0"]
                            command "with" [text "sets"]
                            command "splitevent" [text "ae0",text "ce0a,ce0b"]
                            command "mergeevents" [text "ae1a,ae1b",text "ce1"]
                            command "newevent" [text "ce2"]
                        )]
        cs = M.empty

result1 :: Either [Error] SystemP1
result1 = Right (SystemP h result0)
    where
        h = Hierarchy ["m0","m1"] $ M.singleton "m1" "m0"

name2 :: TestName
name2 = testName "test 2, phase 2 (variables), creating state"

lnZip' :: Ord k => Map k (a -> b) -> Traversal (Map k a) (Map k c) b c
lnZip' m f m' = traverse f $ M.intersectionWith (flip id) m' m

lnZip :: Ord k => Map k b -> Traversal (Map k a) (Map k c) (a,b) c
lnZip m = lnZip' $ flip (,) <$> m

lnZip5 :: Ord k 
       => Map k b0 -> Map k b1 -> Map k b2 -> Map k b3 -> Map k b4
       -> Traversal (Map k a) (Map k z) (a,b0,b1,b2,b3,b4) z
lnZip5 m0 m1 m2 m3 m4 = lnZip' $ (f <$> m0) `op` m1 `op` m2 `op` m3 `op` m4
    where
        f x0 x1 x2 x3 x4 y = (y,x0,x1,x2,x3,x4)
        op = M.intersectionWith ($)

case2 :: IO (Either [Error] SystemP2)
case2 = return $ do
        r <- result1
        runMM (r & (mchTable.lnZip vs) (uncurry make_phase2)) ()
    where
        li = LI "file.ext" 1 1
        s0 = Sort "S0" "S0" 0
        s0' = make_type s0 [] 
        se new_type = zlift (set_type new_type) ztrue
        s1 = Sort "\\S1" "sl@S1" 0
        s1' = make_type s1 [] 
        vs0 = M.fromList
                [ ("x",makeCell $ Machine (Var "x" int) Local li) 
                , ("y",makeCell $ Machine (Var "y" int) Local li)
                , ("p",makeCell $ Evt $ M.singleton (Just "ae1b") (EventDecl (Var "p" bool) Param ("ae1b":|[]) Local li))
                , ("S0",makeCell $ TheoryDef (Def [] "S0" [] (set_type s0') (se s0')) Local li) ]
        vs1 = M.fromList
                [ ("z",makeCell $ Machine (Var "z" int) Local li) 
                , ("y",makeCell $ Machine (Var "y" int) Inherited li) 
                , ("p",makeCell $ Evt $ M.singleton (Just "ce1") (EventDecl (Var "p" bool) Param ("ae1b":|[]) Inherited li))
                , ("q",makeCell $ Evt $ M.singleton (Just "ce2") (EventDecl (Var "q" int) Index ("ce2":|[]) Local li))
                , ("x",makeCell $ DelMch (Just $ Var "x" int) Local li) 
                , ("S0",makeCell $ TheoryDef (Def [] "S0" [] (set_type s0') (se s0')) Local li)
                , ("\\S1",makeCell $ TheoryDef (Def [] "sl@S1" [] (set_type s1') (se s1')) Local li) ]
        vs = M.fromList 
                [ ("m0",vs0) 
                , ("m1",vs1)]

result2 :: Either [Error] SystemP2
result2 = do
        sys <- result1
        let 
            var n = Var n int
            notation m = th_notation $ empty_theory { _extends = m^.pImports }
            parser m = default_setting (notation m)
            li = LI "file.ext" 1 1
            s0 = Sort "S0" "S0" 0
            s0' = make_type s0 [] 
            se new_type = zlift (set_type new_type) ztrue
            s1 = Sort "\\S1" "sl@S1" 0
            s1' = make_type s1 [] 
            fieldsM mid
                | mid == "m0" = [ PStateVars "x" $ var "x"
                                , PStateVars "y" $ var "y" ]
                | otherwise   = [ PStateVars "z" $ var "z"
                                , PDelVars "x" (var "x",li)
                                , PAbstractVars "x" $ var "x" 
                                , PAbstractVars "y" $ var "y" 
                                , PStateVars "y" $ var "y" ]
            fieldsT mid
                | mid == "m0" = [ PDefinitions "S0" (Def [] "S0" [] (set_type s0') (se s0')) ]
                | otherwise   = [ PDefinitions "S0" (Def [] "S0" [] (set_type s0') (se s0')) 
                                , PDefinitions "\\S1" (Def [] "sl@S1" [] (set_type s1') (se s1')) ]
            upMachine mid m m' = makeMachineP2' m 
                        (m^.pCtxSynt & decls %~ M.union (m'^.pAllVars) 
                                     & primed_vars %~ M.union (m'^.pAllVars)) 
                        (fieldsM mid)
            upTheory mid t t' = makeTheoryP2 t (notation t) 
                        (parser t & decls %~ M.union ((t'^.pConstants) `M.union` (t'^.pDefVars))
                                  & sorts %~ M.union (t'^.pTypes)) 
                        (fieldsT mid)
            -- f :: MachineP1' EventP1 TheoryP1 -> MachineP1' EventP2 TheoryP2
            -- f m = m & pContext %~ ()
            --         & pEventRef %~ (\g -> g & traverseLeft %~ upEvent & traverseRight %~ upEvent)
            upEvent m eid e _ = makeEventP2 e (m^.pMchSynt) (m^.pMchSynt) (eventFields eid)
            eventFields eid 
                | eid == Right "ae1b" = [EParams "p" (Var "p" bool)]
                | eid == Right "ce1"  = [EParams "p" (Var "p" bool)]
                | eid == Right "ce2"  = [EIndices "q" (Var "q" int)]
                | otherwise           = []
        return $ sys & mchTable.withKey.traverse %~ \(mid,m) -> 
                layeredUpgradeRec (upTheory mid) (upMachine mid) upEvent upEvent m
        -- (\m -> makeMachineP2' (f m) _ [])

name3 :: TestName
name3 = testName "test 3, phase 2, parsing"

case3 :: IO (Either [Error] SystemP2)
case3 = return $ do
    let ms = M.fromList [("m0",[ms0]),("m1",[ms1])]
        ms0 = makeLatex "file.ext" $ do       
                  command "variable" [text "x,y : \\Int"]                 
                  command "param" [text "ae1b",text "p : \\Bool"]
        ms1 = makeLatex "file.ext" $ do       
                  command "variable" [text "z : \\Int"]                 
                  command "removevar" [text "x"]
                  command "indices" [text "ce2",text "q : \\Int"]
        cs = M.empty
    r <- result1
    runPipeline' ms cs r run_phase2_vars

result3 :: Either [Error] SystemP2
result3 = result2

name4 :: TestName
name4 = testName "test 4, phase 3 (expressions), create object"

case4 :: IO (Either [Error] SystemP3)
case4 = return $ do
        r <- result2
        runMM (r & (mchTable.lnZip es) (uncurry make_phase3)) ()
    where
        decl x con y = do
            scope <- ask
            lift $ x ## makeCell (con y scope li)
        event evt lbl con x = event' evt lbl [evt] con x
        mkEvent evt lbl es con x inh = do
            scope <- ask
            lift $ lbl ## makeEvtCell (Right evt) (con (inh (fromMaybe (evt :| []) $ nonEmpty es,x)) scope li)
                --ExprScope (EventExpr $ M.singleton (Right evt) 
                --    (EvtExprScope $ con (inh (fromMaybe (evt :| []) $ nonEmpty es,x)) scope li)) 
        event' evt lbl es con x = mkEvent evt lbl es con x InhAdd
        del_event evt lbl es con = mkEvent evt lbl es con undefined $ InhDelete . const Nothing
        li = LI "file.ext" 1 1 
        declVar n t = decls %= M.insert n (Var n t)
        c_aux b = ctx $ do
            declVar "x" int
            declVar "y" int
            when b $ expected_type `assign` Nothing
        c  = c_aux False
        c' = c_aux True
        es = M.fromList [("m0",es0),("m1",es1)]
        es0 = runMap $ flip runReaderT Local $ do
                decl "inv0" Invariant $ c [expr| x \le y |]
                --event 
                event "ae0"  "grd0" Guard $ c [expr| x = 0 |]
                event "ae0"  "sch0" CoarseSchedule $ c [expr| y = y |]
                event "ae0"  "sch2" CoarseSchedule $ c [expr| y = 0 |]
                forM_ ["ae1a","ae1b"] $ \evt -> do
                    event evt "default" CoarseSchedule zfalse
                    event evt "act0" Action $ c' [act| y := y + 1 |] 
                    event evt "act1" Action $ c' [act| x := x - 1 |] 
        es1 = runMap $ flip runReaderT Inherited $ do
                local (const Local) $ do
                    decl "prog0" ProgressProp $ LeadsTo [] (c [expr| x \le y |]) (c [expr| x = y |])
                    decl "prog1" ProgressProp $ LeadsTo [] (c [expr| x \le y |]) (c [expr| x = y |])
                    decl "saf0" SafetyProp $ Unless [] (c [expr| x \le y |]) (c [expr| x = y |]) Nothing
                decl "inv0" Invariant $ c [expr| x \le y |]
                --event 
                event' "ce0a" "grd0" ["ae0"] Guard $ c [expr|x = 0|]
                event' "ce0b" "grd0" ["ae0"] Guard $ c [expr|x = 0|]
                local (const Local) $ do
                    del_event "ce0a" "grd0" [] Guard
                    del_event "ce0b" "grd0" [] Guard
                event' "ce0a"  "sch1" ["ce0a"] CoarseSchedule $ c [expr| y = y |]
                event' "ce0a"  "sch2" ["ae0"] CoarseSchedule $ c [expr| y = 0 |]
                event' "ce0b"  "sch0" ["ae0"] CoarseSchedule $ c [expr| y = y |]
                event' "ce0b"  "sch2" ["ae0"] CoarseSchedule $ c [expr| y = 0 |]

                forM_ [("ce1",["ae1a","ae1b"]),("ce2",[])] $ \(evt,es) -> 
                    event' evt "default" es CoarseSchedule zfalse
                event' "ce1" "act0" ["ae1a","ae1b"] Action $ c [act| y := y + 1 |]
                event' "ce1" "act1" ["ae1a","ae1b"] Action $ c' [act| x := x - 1 |] 
                local (const Local) $
                    del_event "ce1" "act1" ["ae1a","ae1b"] Action -- $ c [act| x := x - 1 |]

decl :: String -> GenericType -> State ParserSetting ()
decl n t = decls %= M.insert n (Var n t)

result4 :: Either [Error] SystemP3
result4 = (mchTable.withKey.traverse %~ uncurry upgradeAll) <$> result3
    where
        upgradeAll mid = upgrade newThy (newMch mid) (newEvt mid) (newEvt mid)
        (x,x',xvar)  = prog_var "x" int
        decl n t = decls %= M.insert n (Var n t)
        c_aux b = ctx $ do
            decl "x" int
            decl "y" int
            when b $ expected_type `assign` Nothing
        c  = c_aux False
        c' = c_aux True
        newMch mid m 
            | mid == "m0" = makeMachineP3' m empty_property_set 
                    (makePropertySet' [Inv "inv0" $ c [expr| x \le y |]])
                    [PInvariant "inv0" $ c [expr| x \le y |]]
            | otherwise = makeMachineP3' m 
                    (makePropertySet' [Inv "inv0" $ c [expr| x \le y |]])
                    (makePropertySet' 
                        [ Progress "prog1" prog1
                        , Progress "prog0" prog0
                        , Safety "saf0" saf0 ])
                    [ PInvariant "inv0" $ c [expr| x \le y |]
                    , PProgress "prog1" prog1
                    , PProgress "prog0" prog0
                    , PSafety "saf0" saf0 ]
        prog0 = LeadsTo [] (c [expr| x \le y |]) (c [expr| x = y |])
        prog1 = LeadsTo [] (c [expr| x \le y |]) (c [expr| x = y |])
        saf0  = Unless [] (c [expr| x \le y |]) (c [expr| x = y |]) Nothing
        newThy m = makeTheoryP3 m []
        newEvt mid _m (Right eid) e 
            | eid `elem` ["ae0","ce0a","ce0b"] = makeEventP3 e $ evtField mid eid
            | otherwise = makeEventP3 e $ [ ECoarseSched "default" zfalse] ++ evtField mid eid
        newEvt _mid _m (Left SkipEvent) e = makeEventP3 e [ECoarseSched "default" zfalse]
        evtField mid eid
            | eid == "ae0"                 = [ EGuards  "grd0" $ c [expr|x = 0|]
                                             , ECoarseSched "sch0" $ c [expr|y = y|] 
                                             , ECoarseSched "sch2" $ c [expr|y = 0|]]
            | eid == "ae1a"                = [EActions "act0" $ c' [act| y := y + 1 |] 
                                             ,EActions "act1" $ c' [act| x := x - 1 |] ]
            | eid == "ae1b"                = [EActions "act0" $ c' [act| y := y + 1 |] 
                                             ,EActions "act1" $ c' [act| x := x - 1 |] ]
            | eid == "ce0a"                = [ ECoarseSched "sch1" $ c [expr|y = y|] 
                                             , ECoarseSched "sch2" $ c [expr|y = 0|]]
            | eid == "ce0b"                = [ ECoarseSched "sch0" $ c [expr|y = y|] 
                                             , ECoarseSched "sch2" $ c [expr|y = 0|]]
            | eid == "ce1" && mid == "m1"  = [ EActions "act0" $ c' [act| y := y + 1 |] 
                                             , EWitness xvar $ $typeCheck$ x' `mzeq` (x - 1) ]
            | otherwise = []

name5 :: TestName
name5 = testName "test 5, phase 3, parsing"

case5 :: IO (Either [Error] SystemP3)
case5 = return $ do
    let ms = M.fromList [("m0",[ms0]),("m1",[ms1])]
        ms0 = makeLatex "file.ext" $ do       
                  command "invariant" [text "inv0",text "x \\le y"]                 
                  command "evguard" [text "ae0", text "grd0", text "x = 0"]
                  command "cschedule" [text "ae0", text "sch0", text "y = y"]
                  command "cschedule" [text "ae0", text "sch2", text "y = 0"]
                  command "evbcmeq" [text "ae1a", text "act0", text "y", text "y+1"]
                  command "evbcmeq" [text "ae1b", text "act0", text "y", text "y+1"]
                  command "evbcmeq" [text "ae1a", text "act1", text "x", text "x-1"]
                  command "evbcmeq" [text "ae1b", text "act1", text "x", text "x-1"]
        ms1 = makeLatex "file.ext" $ do       
                  command "removeguard"  [text "ce0a",text "grd0"]
                  command "removeguard"  [text "ce0b",text "grd0"]
                  command "removecoarse" [text "ce0a",text "sch0"]
                  command "cschedule" [text "ce0a", text "sch1", text "y = y"]
                  command "progress"  [text "prog0",text "x \\le y",text "x = y"]
                  command "progress"  [text "prog1",text "x \\le y",text "x = y"]
                  command "safety" [text "saf0",text "x \\le y",text "x = y"]
                  command "removeact" [text "ce1", text "act1"] 
        cs = M.empty
    r <- result2
    runPipeline' ms cs r run_phase3_exprs

result5 :: Either [Error] SystemP3
result5 = result4

name6 :: TestName
name6 = testName "test 6, phase 4 (proofs), create object"

case6 :: IO (Either [Error] SystemP4)
case6 = return $ do
        r <- result4
        return $ r & (mchTable.lnZip5 cSchRef fSchRef liveProof comment proof) %~ 
                    uncurry6 make_phase4
    where
        li = LI "file.ext" 1 1
        ms = M.fromList [("m0",()),("m1",())]
        ch = ScheduleChange 
                (M.singleton "sch0" ()) 
                (M.singleton "sch1" ()) 
                (M.singleton "sch2" ()) 
                ("prog1", prog1) 
                ("saf0", saf0)
        cSchRef = runMap' $ do
            "m0" ## M.empty
            "m1" ## runMap' (do
                "ae0" ## [(("SCH/m1",ch),li)])
        fSchRef = runMap' $ do
            "m0" ## M.empty
            "m1" ## runMap' (do
                "ae0" ## Just (("prog1",prog1),li))
        liveProof = M.insert "m1" (runMap' $ do
            "prog0" ## ((Rule $ Monotonicity (getExpr <$> prog1) "prog1" (getExpr <$> prog1),[("prog0","prog1")]),li))
            $ M.empty <$ ms
        comment = M.empty <$ ms
        proof = M.empty <$ ms
        prog1 = LeadsTo [] (c [expr|x \le y|]) (c [expr|x = y|])
        saf0  = Unless [] (c [expr|x \le y|]) (c [expr|x = y|]) Nothing
        c  = ctx $ do
            decl "x" int
            decl "y" int
        uncurry6 f (x0,x1,x2,x3,x4,x5) = f x0 x1 x2 x3 x4 x5
        --x  = fst $ var "x" int
        --y  = fst $ var "y" (int ::

result6 :: Either [Error] SystemP4
result6 = (mchTable.withKey.traverse %~ uncurry upgradeAll) <$> result5
    where
        upgradeAll mid = upgrade id (newMch mid) (newEvt mid) (newEvt mid)
        --newThy t = 
        newEvt mid _m eid e 
            | eid == Right "ae0" && mid == "m1" = makeEventP4 e [("SCH/m1",ch)] (Just ("prog1",prog1)) []
            | otherwise           = makeEventP4 e [] Nothing []
        newMch mid m 
            | mid == "m1" = makeMachineP4' m [PLiveRule "prog0" (Rule $ Monotonicity (getExpr <$> prog1) "prog1" (getExpr <$> prog1))]
            | otherwise   = makeMachineP4' m []
        ch = ScheduleChange 
                (M.singleton "sch0" ()) 
                (M.singleton "sch1" ()) 
                (M.singleton "sch2" ()) 
                ("prog1", prog1) 
                ("saf0", saf0)
        prog1 = LeadsTo [] (c [expr|x \le y|]) (c [expr|x = y|])
        saf0  = Unless [] (c [expr|x \le y|]) (c [expr|x = y|]) Nothing
        c  = ctx $ do
            decl "x" int
            decl "y" int

name7 :: TestName
name7 = testName "test 7, phase 4, parsing"

case7 :: IO (Either [Error] SystemP4)
case7 = return $ do
    let ms = M.fromList [("m0",[ms0]),("m1",[ms1])]
        ms0 = makeLatex "file.ext" $ do       
                  command "invariant" [text "inv0",text "x \\le y"]                 
                  command "evguard" [text "ae0", text "grd0", text "x = 0"]
                  command "evbcmeq" [text "ae1a", text "act0", text "y", text "y+1"]
        ms1 = makeLatex "file.ext" $ do       
                  command "replace" [text "ae0",text "sch0",text "sch1",text "sch2",text "prog1",text "saf0"]
                  command "replacefine" [text "ae0",text "prog1"]
                  command "refine" [text "prog0",text "monotonicity",text "prog1",text ""]
                  --command "removeguard" [text "ce0b",text "grd0"]
        cs = M.empty
    r <- result5
    runPipeline' ms cs r run_phase4_proofs

result7 :: Either [Error] SystemP4
result7 = result6

name8 :: TestName
name8 = testName "test 8, make machine"

case8 :: IO (Either [Error] (SystemP Machine))
case8 = return $ do
    r <- result7 
    runMM (r & mchTable (M.traverseWithKey make_machine)) ()

result8 :: Either [Error] (SystemP Machine)
result8 = Right $ SystemP h ms
    where
        h = Hierarchy ["m0","m1"] (singleton "m1" "m0")
        (x,x',xvar) = prog_var "x" int
        ms = M.fromList [("m0",m0),("m1",m1)]
        s0 = Sort "S0" "S0" 0
        s1 = Sort "\\S1" "sl@S1" 0
        setS0 = set_type $ make_type s0 []
        setS1 = set_type $ make_type s1 []
        sorts0 = symbol_table [s0]
        sorts1 = symbol_table [s0,s1]
        defs0 = symbol_table [Def [] "S0" [] setS0 (zlift setS0 ztrue)]
        defs1 = M.fromList $ [ ("S0",Def [] "S0" [] setS0 (zlift setS0 ztrue))
                             , ("\\S1",Def [] "sl@S1" [] setS1 (zlift setS1 ztrue))]
        vars0 = symbol_table [Var "x" int,Var "y" int]
        vars1 = symbol_table [Var "z" int,Var "y" int]
        c' f = c $ f.(expected_type .~ Nothing)
        c = ctx $ do
            decl "x" int
            decl "y" int
        m0 = (empty_machine "m0") & content AST.assert %~ \m -> m
                & theory.types .~ sorts0
                & theory.defs  .~ defs0
                & variables    .~ vars0
                & events    .~ evts0
                & props.inv .~ M.fromList [("inv0",c [expr| x \le y |])]
        p = c [expr| x \le y |]
        q = c [expr| x = y |]
        pprop = LeadsTo [] p q
        pprop' = getExpr <$> pprop
        sprop = Unless [] p q Nothing
        m1 = (empty_machine "m1") & content AST.assert %~ \m -> m
                & theory.types .~ sorts1
                & theory.defs .~ defs1
                & theory.extends %~ M.insert "sets" set_theory
                & del_vars .~ symbol_table [Var "x" int]
                & abs_vars .~ vars0
                & variables .~ vars1
                & events .~ evts1
                & inh_props.inv  .~ M.fromList [("inv0",c [expr| x \le y |])]
                & props.progress .~ M.fromList [("prog0",pprop),("prog1",pprop)]
                & props.safety .~ M.singleton "saf0" sprop
                & derivation .~ M.fromList [("prog0",Rule $ Monotonicity pprop' "prog1" pprop'),("prog1",Rule Add)]
        --y = Var "y" int
        skipLbl = Left SkipEvent
        ae0sched = def & old .~ ae0Evt
                       & c_sched_ref .~ [replace ("prog1",pprop) ("saf0",sprop)
                                          & remove .~ singleton "sch0" ()
                                          & add    .~ singleton "sch1" ()
                                          & keep   .~ singleton "sch2" () ]
                       & f_sched_ref .~ Just ("prog1",pprop) 
        ae0Evt = def
            & coarse_sched .~ M.fromList 
                [("sch0",c [expr| y = y|]),("sch2",c [expr| y = 0 |])]
            & guards .~ M.fromList
                [("grd0",c [expr| x = 0 |])]
        ae1aEvt = def
            & coarse_sched .~ M.fromList 
                [("default",c [expr| \false |])]
            & actions .~ M.fromList
                [ ("act0",c' [act| y := y + 1 |])
                , ("act1",c' [act| x := x - 1 |])]
        ae1bEvt = def
            & coarse_sched .~ M.fromList 
                [("default",c [expr| \false |])]
            & params .~ symbol_table [Var "p" bool]
            & actions .~ M.fromList
                [ ("act0",c' [act| y := y + 1 |])
                , ("act1",c' [act| x := x - 1 |])]
        ce0aEvt = def
            & coarse_sched .~ M.fromList 
                [("sch1",c [expr| y = y|]),("sch2",c [expr| y = 0 |])]
        ce0bEvt = def
            & coarse_sched .~ M.fromList 
                [("sch0",c [expr| y = y|]),("sch2",c [expr| y = 0 |])]
        ce1Evt = def
            & params .~ symbol_table [Var "p" bool]
            & coarse_sched .~ M.fromList 
                [("default",c [expr| \false |])]
            & witness .~ M.fromList
                [ (xvar, $typeCheck$ x' `mzeq` (x - 1)) ]
            & actions .~ M.fromList
                [ ("act0",c' [act| y := y + 1 |])]
            & abs_actions .~ M.fromList
                [ ("act0",c' [act| y := y + 1 |])
                , ("act1",c' [act| x := x - 1 |])]
            -- & eql_vars .~ symbol_table [y]
        ce2Evt = def
            & AST.indices .~ symbol_table [Var "q" int]
            & coarse_sched .~ M.fromList 
                [("default",c [expr| \false |])]
        skipEvt = def 
            & coarse_sched .~ M.fromList 
                [("default",c [expr| \false |])]
        evts0 = fromJust $ makeGraph $ do
            ae0  <- newRightVertex (Right "ae0") (def & new .~ ae0Evt)
            ae1a <- newRightVertex (Right "ae1a") (def & new .~ ae1aEvt)
            ae1b <- newRightVertex (Right "ae1b") (def & new .~ ae1bEvt)
            cskip <- newRightVertex skipLbl (def & new .~ skipEvt)
            askip <- newLeftVertex skipLbl (def & old .~ skipEvt)
            forM_ [ae0,ae1a,ae1b,cskip] $ newEdge askip
        evts1 = fromJust $ makeGraph $ do
            ae0 <- newLeftVertex (Right "ae0") ae0sched
            ae1a <- newLeftVertex (Right "ae1a") (def & old .~ ae1aEvt)
            ae1b <- newLeftVertex (Right "ae1b") (def & old .~ ae1bEvt)
            askip <- newLeftVertex skipLbl (def & old .~ skipEvt)
            ce0a <- newRightVertex (Right "ce0a") (def & new .~ ce0aEvt)
            ce0b <- newRightVertex (Right "ce0b") (def & new .~ ce0bEvt)
            ce1 <- newRightVertex (Right "ce1") ce1Evt
            ce2 <- newRightVertex (Right "ce2") (def & new .~ ce2Evt)
            cskip <- newRightVertex skipLbl (def & new .~ skipEvt)
            newEdge ae0 ce0a
            newEdge ae0 ce0b
            newEdge ae1a ce1
            newEdge ae1b ce1
            newEdge askip ce2
            newEdge askip cskip

name9 :: TestName
name9 = testName "QuickCheck inheritance"

instance (Ord k,Arbitrary k,Arbitrary a) => Arbitrary (Map k a) where
    arbitrary = M.fromList <$> arbitrary

prop_inherit_equiv :: Hierarchy Int
                   -> Property
prop_inherit_equiv h = forAll (mkMap h) $ \m -> 
    inheritWith' id (L.map.(+)) (++) h m == inheritWithAlt id (L.map.(+)) (++) h (m :: Map Int [Int])

case9 :: IO Bool
case9 = f <$> quickCheckResult prop_inherit_equiv
    where
        f (Success _ _ _) = True
        f _ = False

result9 :: Bool
result9 = True

mkMap :: (Arbitrary a,Ord k) => Hierarchy k -> Gen (Map k [a])
mkMap (Hierarchy xs _) = M.fromList.L.zip xs <$> replicateM (L.length xs) arbitrary

--see :: Map ProgId ProgressProp
seeA :: IO (Map Int [Int])
seeA = return $ inheritWith' id (L.map.(+)) (++) hierarchy m

hierarchy :: Hierarchy Int
hierarchy = Hierarchy {order = [2,1], edges = M.fromList [(1,2)]}

m :: Map Int [Int]
m = M.fromList [(1,[3,-3,-2]),(2,[5,-1])]

seeE :: IO (Map Int [Int])
seeE = return $ inheritWithAlt id (L.map.(+)) (++) hierarchy m

--seeLens :: Either [Error] SystemP3 -> [EventId]
--seeLens = view $ to fromRight'.mchTable.at "m1".to fromJust.pNewEvents.eEventId.traverse.to (:[])