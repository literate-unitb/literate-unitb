module Document.Tests.Puzzle 
    ( test_case )
where

    -- Modules
import Document.Document
import Document.Tests.Suite

import Documentation.SummaryGen

import Logic.Expr
import Logic.Proof

import UnitB.AST

    -- Library
import Control.Monad

import Data.Either.Combinators
import Data.Map

import Tests.UnitTest

test_case :: TestCase
test_case = test_cases 
        "The king and his advisors puzzle"
        [ POCase "puzzle, m0" case0 result0
        , POCase "puzzle, m1" case1 result1
        , Case "puzzle, proof obligation" case2 result2
        , Case "puzzle, event visit" case3 result3
        , Case "puzzle, visit enablement, PO" case4 result4
        , Case "puzzle, visit negation, PO" case5 result5
        , Case "puzzle, remove default with weakento" case6 result6
        ]

path0 :: FilePath
path0 = "Tests/puzzle/puzzle.tex"

case0 :: IO (String, Map Label Sequent)
case0 = verify path0 0

result0 :: String
result0 = unlines
    [ "  o  m0/INIT/FIS/b"
    , "  o  m0/INIT/WD"
    , "  o  m0/INV/WD"
    , "  o  m0/prog0/PROG/WD/lhs"
    , "  o  m0/prog0/PROG/WD/rhs"
    , "  o  m0/prog0/REF/ensure/m0/SAF/WD/lhs"
    , "  o  m0/prog0/REF/ensure/m0/SAF/WD/rhs"
    , "  o  m0/prog0/REF/ensure/m0/TR/WD"
    , "  o  m0/prog0/REF/ensure/m0/TR/term/EN"
    , "  o  m0/prog0/REF/ensure/m0/TR/term/NEG"
    , "  o  m0/prog0/REF/ensure/m0/term/SAF"
    , "  o  m0/term/FIS/b@prime"
    , "  o  m0/term/SCH"
    , "  o  m0/term/SCH/m0/0/REF/weaken"
    , "  o  m0/term/WD/ACT/act0"
    , "  o  m0/term/WD/C_SCH"
    , "  o  m0/term/WD/F_SCH"
    , "  o  m0/term/WD/GRD"
    , "passed 18 / 18"
    ]

case1 :: IO (String, Map Label Sequent)
case1 = verify path0 1

result1 :: String
result1 = unlines
    [ "  o  m1/INIT/FIS/b"
    , "  o  m1/INIT/INV/inv0"
    , "  o  m1/INIT/WD"
    , "  o  m1/INV/WD"
    , "  o  m1/prog1/PROG/WD/lhs"
    , "  o  m1/prog1/PROG/WD/rhs"
    , "  o  m1/prog1/REF/induction/lhs"
    , "  o  m1/prog1/REF/induction/rhs"
    , "  o  m1/prog2/PROG/WD/lhs"
    , "  o  m1/prog2/PROG/WD/rhs"
    , "  o  m1/prog2/REF/PSP/lhs"
    , "  o  m1/prog2/REF/PSP/rhs"
    , "  o  m1/prog3/PROG/WD/lhs"
    , "  o  m1/prog3/PROG/WD/rhs"
    , "  o  m1/prog3/REF/ensure/m1/SAF/WD/lhs"
    , "  o  m1/prog3/REF/ensure/m1/SAF/WD/rhs"
    , "  o  m1/prog3/REF/ensure/m1/TR/WD"
    , "  o  m1/prog3/REF/ensure/m1/TR/WD/witness/p"
    , "  o  m1/prog3/REF/ensure/m1/TR/WFIS/p/p@prime"
    , "  o  m1/prog3/REF/ensure/m1/TR/visit/EN"
    , "  o  m1/prog3/REF/ensure/m1/TR/visit/NEG"
    , "  o  m1/prog3/REF/ensure/m1/term/SAF"
    , "  o  m1/prog3/REF/ensure/m1/visit/SAF"
    , "  o  m1/saf1/SAF/WD/lhs"
    , "  o  m1/saf1/SAF/WD/rhs"
    , "  o  m1/saf2/SAF/WD/lhs"
    , "  o  m1/saf2/SAF/WD/rhs"
    , "  o  m1/term/FIS/b@prime"
    , "  o  m1/term/FIS/vs@prime"
    , "  o  m1/term/INV/inv0"
    , "  o  m1/term/SAF/saf1"
    , "  o  m1/term/SAF/saf2"
    , "  o  m1/term/SCH"
    , "  o  m1/term/SCH/m1/0/REF/delay/prog/lhs"
    , "  o  m1/term/SCH/m1/0/REF/delay/prog/rhs"
    , "  o  m1/term/SCH/m1/0/REF/delay/saf/lhs"
    , "  o  m1/term/SCH/m1/0/REF/delay/saf/rhs"
    , "  o  m1/term/WD/C_SCH"
    , "  o  m1/term/WD/F_SCH"
    , "  o  m1/term/WD/GRD"
    , "  o  m1/visit/FIS/b@prime"
    , "  o  m1/visit/FIS/vs@prime"
    , "  o  m1/visit/INV/inv0"
    , "  o  m1/visit/SAF/saf1"
    , "  o  m1/visit/SAF/saf2"
    , "  o  m1/visit/SCH"
    , "  o  m1/visit/SCH/m1/0/REF/weaken"
    , "  o  m1/visit/WD/ACT/act1"
    , "  o  m1/visit/WD/C_SCH"
    , "  o  m1/visit/WD/F_SCH"
    , "  o  m1/visit/WD/GRD"
    , "passed 51 / 51"
    ]

case2 :: IO String
case2 = proof_obligation path0 "m1/prog1/REF/induction/rhs" 1

result2 :: String
result2 = unlines
    [ "(declare-datatypes (a) ( (Maybe (Just (fromJust a)) Nothing) ))"
    , "(declare-datatypes () ( (Null null) ))"
    , "(declare-datatypes (a b) ( (Pair (pair (first a) (second b))) ))"
    , "; comment: we don't need to declare the sort Bool"
    , "; comment: we don't need to declare the sort Int"
    , "(declare-sort P 0)"
    , "; comment: we don't need to declare the sort Real"
    , "(define-sort set (a) (Array a Bool))"
    , "(declare-const V (set P))"
    , "(declare-const b Bool)"
    , "(declare-const b@prime Bool)"
    , "(declare-const vs (set P))"
    , "(declare-const vs@prime (set P))"
    , "(declare-fun mk-set@@P (P) (set P))"
    , "(define-fun P () (set P) ( (as const (set P)) true ))"
    , "(define-fun compl@@P ( (s1 (set P)) ) (set P) ((_ map not) s1))"
    , "(define-fun elem@@P ( (x P) (s1 (set P)) ) Bool (select s1 x))"
    , "(define-fun empty-set@@P"
    , "            ()"
    , "            (set P)"
    , "            ( (as const (set P))"
    , "              false ))"
    , "(define-fun set-diff@@P"
    , "            ( (s1 (set P))"
    , "              (s2 (set P)) )"
    , "            (set P)"
    , "            (intersect s1 ((_ map not) s2)))"
    , "(define-fun st-subset@@P"
    , "            ( (s1 (set P))"
    , "              (s2 (set P)) )"
    , "            Bool"
    , "            (and (subset s1 s2) (not (= s1 s2))))"
    , "(assert (forall ( (x P)"
    , "                  (y P) )"
    , "                (! (= (elem@@P x (mk-set@@P y)) (= x y))"
    , "                   :pattern"
    , "                   ( (elem@@P x (mk-set@@P y)) ))))"
    , "(assert (not (forall ( (V (set P)) )"
    , "                     (=> true"
    , "                         (=> (or (st-subset@@P (set-diff@@P P vs) V) (= vs P))"
    , "                             (or (and (subset (set-diff@@P P vs) V)"
    , "                                      (subset empty-set@@P (set-diff@@P P vs)))"
    , "                                 (= vs P)))))))"
    , "(assert (not (=> (or (st-subset@@P (set-diff@@P P vs) V) (= vs P))"
    , "                 (or (and (subset (set-diff@@P P vs) V)"
    , "                          (subset empty-set@@P (set-diff@@P P vs)))"
    , "                     (= vs P)))))"
    , "; inv0"
    , "(assert (=> b (= vs P)))"
    , "(assert (not (=> (st-subset@@P (set-diff@@P P vs) V)"
    , "                 (and (subset (set-diff@@P P vs) V)"
    , "                      (subset empty-set@@P (set-diff@@P P vs))))))"
    , "(check-sat-using (or-else (then qe smt)"
    , "                          (then simplify smt)"
    , "                          (then skip smt)"
    , "                          (then (using-params simplify :expand-power true) smt)))"
    ]

case3 :: IO String
case3 = do
    s <- fromRight' `liftM` parse_system path0
    let ms  = machines s
        m   = ms ! "m1"
        visit = label "visit"
        evt  = events m ! visit
    return $ getListing s $ event_summary' m visit evt

result3 :: String
result3 = unlines
    [ "\\noindent \\ref{visit} [p] \\textbf{event}"
    , "\\begin{block}"
    , "  \\item   \\textbf{begin}"
    , "  \\begin{block}"
    , "  \\item[ \\eqref{visitact1} ]$vs \\bcmeq vs \\bunion \\{ p \\} $ %"
    , "  \\end{block}"
    , "  \\item   \\textbf{end} \\\\"
    , "\\end{block}"
    ]

case4 :: IO String
case4 = proof_obligation path0 "m1/prog3/REF/ensure/m1/TR/visit/EN" 1

result4 :: String
result4 = unlines
    [ "(declare-datatypes (a) ( (Maybe (Just (fromJust a)) Nothing) ))"
    , "(declare-datatypes () ( (Null null) ))"
    , "(declare-datatypes (a b) ( (Pair (pair (first a) (second b))) ))"
    , "; comment: we don't need to declare the sort Bool"
    , "; comment: we don't need to declare the sort Int"
    , "(declare-sort P 0)"
    , "; comment: we don't need to declare the sort Real"
    , "(define-sort set (a) (Array a Bool))"
    , "(declare-const V (set P))"
    , "(declare-const b Bool)"
    , "(declare-const b@prime Bool)"
    , "(declare-const vs (set P))"
    , "(declare-const vs@prime (set P))"
    , "(declare-fun mk-set@@P (P) (set P))"
    , "(declare-fun p@param () P)"
    , "(define-fun P () (set P) ( (as const (set P)) true ))"
    , "(define-fun compl@@P ( (s1 (set P)) ) (set P) ((_ map not) s1))"
    , "(define-fun elem@@P ( (x P) (s1 (set P)) ) Bool (select s1 x))"
    , "(define-fun empty-set@@P"
    , "            ()"
    , "            (set P)"
    , "            ( (as const (set P))"
    , "              false ))"
    , "(define-fun set-diff@@P"
    , "            ( (s1 (set P))"
    , "              (s2 (set P)) )"
    , "            (set P)"
    , "            (intersect s1 ((_ map not) s2)))"
    , "(define-fun st-subset@@P"
    , "            ( (s1 (set P))"
    , "              (s2 (set P)) )"
    , "            Bool"
    , "            (and (subset s1 s2) (not (= s1 s2))))"
    , "(assert (forall ( (x P)"
    , "                  (y P) )"
    , "                (! (= (elem@@P x (mk-set@@P y)) (= x y))"
    , "                   :pattern"
    , "                   ( (elem@@P x (mk-set@@P y)) ))))"
    , "(assert (not (elem@@P p@param vs)))"
    , "; inv0"
    , "(assert (=> b (= vs P)))"
    , "(assert (not true))"
    , "(check-sat-using (or-else (then qe smt)"
    , "                          (then simplify smt)"
    , "                          (then skip smt)"
    , "                          (then (using-params simplify :expand-power true) smt)))"
    ]

case5 :: IO String
case5 = proof_obligation path0 "m1/prog3/REF/ensure/m1/TR/visit/NEG" 1

result5 :: String
result5 = unlines
    [ "(declare-datatypes (a) ( (Maybe (Just (fromJust a)) Nothing) ))"
    , "(declare-datatypes () ( (Null null) ))"
    , "(declare-datatypes (a b) ( (Pair (pair (first a) (second b))) ))"
    , "; comment: we don't need to declare the sort Bool"
    , "; comment: we don't need to declare the sort Int"
    , "(declare-sort P 0)"
    , "; comment: we don't need to declare the sort Real"
    , "(define-sort set (a) (Array a Bool))"
    , "(declare-const V (set P))"
    , "(declare-const b Bool)"
    , "(declare-const b@prime Bool)"
    , "(declare-const vs (set P))"
    , "(declare-const vs@prime (set P))"
    , "(declare-fun mk-set@@P (P) (set P))"
    , "(declare-fun p@param () P)"
    , "(define-fun P () (set P) ( (as const (set P)) true ))"
    , "(define-fun compl@@P ( (s1 (set P)) ) (set P) ((_ map not) s1))"
    , "(define-fun elem@@P ( (x P) (s1 (set P)) ) Bool (select s1 x))"
    , "(define-fun empty-set@@P"
    , "            ()"
    , "            (set P)"
    , "            ( (as const (set P))"
    , "              false ))"
    , "(define-fun set-diff@@P"
    , "            ( (s1 (set P))"
    , "              (s2 (set P)) )"
    , "            (set P)"
    , "            (intersect s1 ((_ map not) s2)))"
    , "(define-fun st-subset@@P"
    , "            ( (s1 (set P))"
    , "              (s2 (set P)) )"
    , "            Bool"
    , "            (and (subset s1 s2) (not (= s1 s2))))"
    , "(assert (forall ( (x P)"
    , "                  (y P) )"
    , "                (! (= (elem@@P x (mk-set@@P y)) (= x y))"
    , "                   :pattern"
    , "                   ( (elem@@P x (mk-set@@P y)) ))))"
    , "(assert (not (elem@@P p@param vs)))"
    , "; SKIP:b"
    , "(assert (= b@prime b))"
    , "; act1"
    , "(assert (= vs@prime (union vs (mk-set@@P p@param))))"
    , "; inv0"
    , "(assert (=> b (= vs P)))"
    , "(assert (not (=> (and (= (set-diff@@P P vs) V)"
    , "                      (not (= vs P))"
    , "                      (= (set-diff@@P P vs) V))"
    , "                 (not (and (= (set-diff@@P P vs@prime) V)"
    , "                           (not (= vs@prime P))"
    , "                           (= (set-diff@@P P vs@prime) V))))))"
    , "(check-sat-using (or-else (then qe smt)"
    , "                          (then simplify smt)"
    , "                          (then skip smt)"
    , "                          (then (using-params simplify :expand-power true) smt)))"
    ]

case6 :: IO String
case6 = proof_obligation path0 "m1/visit/SCH/m1/0/REF/weaken" 1

result6 :: String
result6 = unlines
    [ "(declare-datatypes (a) ( (Maybe (Just (fromJust a)) Nothing) ))"
    , "(declare-datatypes () ( (Null null) ))"
    , "(declare-datatypes (a b) ( (Pair (pair (first a) (second b))) ))"
    , "; comment: we don't need to declare the sort Bool"
    , "; comment: we don't need to declare the sort Int"
    , "(declare-sort P 0)"
    , "; comment: we don't need to declare the sort Real"
    , "(define-sort set (a) (Array a Bool))"
    , "(declare-const b Bool)"
    , "(declare-const b@prime Bool)"
    , "(declare-const vs (set P))"
    , "(declare-const vs@prime (set P))"
    , "(declare-fun mk-set@@P (P) (set P))"
    , "(define-fun P () (set P) ( (as const (set P)) true ))"
    , "(define-fun compl@@P ( (s1 (set P)) ) (set P) ((_ map not) s1))"
    , "(define-fun elem@@P ( (x P) (s1 (set P)) ) Bool (select s1 x))"
    , "(define-fun empty-set@@P"
    , "            ()"
    , "            (set P)"
    , "            ( (as const (set P))"
    , "              false ))"
    , "(define-fun set-diff@@P"
    , "            ( (s1 (set P))"
    , "              (s2 (set P)) )"
    , "            (set P)"
    , "            (intersect s1 ((_ map not) s2)))"
    , "(define-fun st-subset@@P"
    , "            ( (s1 (set P))"
    , "              (s2 (set P)) )"
    , "            Bool"
    , "            (and (subset s1 s2) (not (= s1 s2))))"
    , "(assert (forall ( (x P)"
    , "                  (y P) )"
    , "                (! (= (elem@@P x (mk-set@@P y)) (= x y))"
    , "                   :pattern"
    , "                   ( (elem@@P x (mk-set@@P y)) ))))"
    , "; inv0"
    , "(assert (=> b (= vs P)))"
    , "(assert (not true))"
    , "(check-sat-using (or-else (then qe smt)"
    , "                          (then simplify smt)"
    , "                          (then skip smt)"
    , "                          (then (using-params simplify :expand-power true) smt)))"
    ]

