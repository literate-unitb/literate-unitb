module Document.Tests.TrainStationRefinement 
    ( test, test_case, path3 )
where

    -- Modules
import Document.Tests.Suite

    -- Libraries
import Data.List.NonEmpty as NE
import Test.UnitTest

test_case :: TestCase
test_case = test

test :: TestCase
test = test_cases
            "train station example, with refinement"
            [ poCase "verify machine m0 (ref)" (verify path0 0) result0
            , poCase "verify machine m1 (ref)" (verify path0 1) result1
            , stringCase "Feasibility in m1" case6 result6
            , poCase "verify machine m2 (ref)" (verify path0 2) result2
            , poCase "verify machine m2 (ref), in many files" 
                (verifyFiles (NE.fromList [path1,path1']) 2) result2
            , stringCase "cyclic proof of liveness through 3 refinements" (find_errors path3) result3
            , stringCase "refinement of undefined machine" (find_errors path4) result4
            , stringCase "repeated imports" case5 result5
            ]

result0 :: String
result0 = unlines
    [ "  o  m0/m0:enter/FIS/in@prime"
    , "  o  m0/m0:leave/FIS/in@prime"
    , "  o  m0/m0:prog0/LIVE/discharge/tr/lhs"
    , "  o  m0/m0:prog0/LIVE/discharge/tr/rhs"
    , "  o  m0/m0:tr0/TR/WFIS/t/t@prime"
    , "  o  m0/m0:tr0/TR/m0:leave/EN"
    , "  o  m0/m0:tr0/TR/m0:leave/NEG"
    , "passed 7 / 7"
    ]

result1 :: String
result1 = unlines
    [ "  o  m1/INIT/INV/inv0"
    , "  o  m1/m0:enter/FIS/in@prime"
    , "  o  m1/m0:enter/FIS/loc@prime"
    , "  o  m1/m0:enter/INV/inv0"
    , "  o  m1/m0:enter/SAF/m1:saf0"
    , "  o  m1/m0:enter/SAF/m1:saf1"
    , "  o  m1/m0:enter/SAF/m1:saf2"
    , "  o  m1/m0:enter/SAF/m1:saf3"
    , "  o  m1/m0:enter/SCH/ent:grd1"
    , "  o  m1/m0:leave/C_SCH/delay/0/prog/m1:prog0/lhs"
    , "  o  m1/m0:leave/C_SCH/delay/0/prog/m1:prog0/rhs/lv:c1"
    , "  o  m1/m0:leave/C_SCH/delay/0/saf/m0:enter/SAF/m0:leave"
    , "  o  m1/m0:leave/C_SCH/delay/0/saf/m0:leave/SAF/m0:leave"
    , "  o  m1/m0:leave/C_SCH/delay/0/saf/m1:movein/SAF/m0:leave"
    , "  o  m1/m0:leave/C_SCH/delay/0/saf/m1:moveout/SAF/m0:leave"
    , "  o  m1/m0:leave/FIS/in@prime"
    , "  o  m1/m0:leave/FIS/loc@prime"
    , "  o  m1/m0:leave/INV/inv0"
    , "  o  m1/m0:leave/SAF/m1:saf0"
    , "  o  m1/m0:leave/SAF/m1:saf1"
    , "  o  m1/m0:leave/SAF/m1:saf2"
    , "  o  m1/m0:leave/SAF/m1:saf3"
    , "  o  m1/m0:leave/SCH/lv:grd0"
    , "  o  m1/m0:leave/SCH/lv:grd1"
    , "  o  m1/m0:leave/WD/C_SCH"
    , "  o  m1/m0:leave/WD/GRD"
    , "  o  m1/m1:movein/FIS/loc@prime"
    , "  o  m1/m1:movein/INV/inv0"
    , "  o  m1/m1:movein/SAF/m1:saf0"
    , "  o  m1/m1:movein/SAF/m1:saf1"
    , "  o  m1/m1:movein/SAF/m1:saf2"
    , "  o  m1/m1:movein/SAF/m1:saf3"
    , "  o  m1/m1:movein/SCH"
    , "  o  m1/m1:movein/SCH/b"
    , "  o  m1/m1:movein/WD/C_SCH"
    , "  o  m1/m1:movein/WD/GRD"
    , "  o  m1/m1:moveout/FIS/loc@prime"
    , "  o  m1/m1:moveout/INV/inv0"
    , "  o  m1/m1:moveout/SAF/m1:saf0"
    , "  o  m1/m1:moveout/SAF/m1:saf1"
    , "  o  m1/m1:moveout/SAF/m1:saf2"
    , "  o  m1/m1:moveout/SAF/m1:saf3"
    , "  o  m1/m1:moveout/SCH/mo:g1"
    , "  o  m1/m1:moveout/SCH/mo:g2"
    , "  o  m1/m1:moveout/WD/C_SCH"
    , "  o  m1/m1:moveout/WD/GRD"
    , "  o  m1/m1:prog0/LIVE/disjunction/lhs"
    , "  o  m1/m1:prog0/LIVE/disjunction/rhs"
    , "  o  m1/m1:prog0/PROG/WD/rhs"
    , "  o  m1/m1:prog1/LIVE/transitivity/lhs"
    , "  o  m1/m1:prog1/LIVE/transitivity/mhs/0/1"
    , "  o  m1/m1:prog1/LIVE/transitivity/rhs"
    , "  o  m1/m1:prog1/PROG/WD/lhs"
    , "  o  m1/m1:prog1/PROG/WD/rhs"
    , "  o  m1/m1:prog2/LIVE/implication"
    , "  o  m1/m1:prog2/PROG/WD/lhs"
    , "  o  m1/m1:prog2/PROG/WD/rhs"
    , "  o  m1/m1:prog3/LIVE/discharge/saf/lhs"
    , "  o  m1/m1:prog3/LIVE/discharge/saf/rhs"
    , "  o  m1/m1:prog3/LIVE/discharge/tr"
    , "  o  m1/m1:prog3/PROG/WD/lhs"
    , "  o  m1/m1:prog3/PROG/WD/rhs"
    , "  o  m1/m1:prog4/LIVE/discharge/saf/lhs"
    , "  o  m1/m1:prog4/LIVE/discharge/saf/rhs"
    , "  o  m1/m1:prog4/LIVE/discharge/tr"
    , "  o  m1/m1:prog4/PROG/WD/lhs"
    , "  o  m1/m1:prog4/PROG/WD/rhs"
    , "  o  m1/m1:saf0/SAF/WD/rhs"
    , "  o  m1/m1:saf1/SAF/WD/lhs"
    , "  o  m1/m1:saf1/SAF/WD/rhs"
    , "  o  m1/m1:saf2/SAF/WD/lhs"
    , "  o  m1/m1:saf2/SAF/WD/rhs"
    , "  o  m1/m1:saf3/SAF/WD/lhs"
    , "  o  m1/m1:tr0/TR/WD"
    , "  o  m1/m1:tr0/TR/WFIS/t/t@prime"
    , "  o  m1/m1:tr0/TR/m1:moveout/EN"
    , "  o  m1/m1:tr0/TR/m1:moveout/NEG"
    , "  o  m1/m1:tr1/TR/WD"
    , "  o  m1/m1:tr1/TR/WFIS/t/t@prime"
    , "  o  m1/m1:tr1/TR/m1:movein/EN"
    , "  o  m1/m1:tr1/TR/m1:movein/NEG"
    , "passed 81 / 81"
    ]

result2 :: String
result2 = unlines
    [ "  o  m2/INIT/INV/m2:inv0"
    , "  o  m2/INV/WD"
    , "  o  m2/m0:enter/FIS/in@prime"
    , "  o  m2/m0:enter/FIS/loc@prime"
    , "  o  m2/m0:enter/INV/m2:inv0"
    , "  o  m2/m0:enter/SAF/m2:saf1"
    , "  o  m2/m0:enter/SAF/m2:saf2"
    , "  o  m2/m0:enter/SCH/et:g1"
    , "  o  m2/m0:enter/WD/GRD"
    , "  o  m2/m0:leave/FIS/in@prime"
    , "  o  m2/m0:leave/FIS/loc@prime"
    , "  o  m2/m0:leave/INV/m2:inv0/assertion/hyp3/easy"
    , "  o  m2/m0:leave/INV/m2:inv0/assertion/hyp4/easy"
    , "  o  m2/m0:leave/INV/m2:inv0/assertion/hyp5/easy"
    , "  o  m2/m0:leave/INV/m2:inv0/assertion/hyp6/easy"
    , "  o  m2/m0:leave/INV/m2:inv0/assertion/hyp7/goal"
    , "  o  m2/m0:leave/INV/m2:inv0/assertion/hyp7/hypotheses"
    , "  o  m2/m0:leave/INV/m2:inv0/assertion/hyp7/relation"
    , "  o  m2/m0:leave/INV/m2:inv0/assertion/hyp7/step 1"
    , "  o  m2/m0:leave/INV/m2:inv0/assertion/hyp7/step 2"
    , "  o  m2/m0:leave/INV/m2:inv0/assertion/hyp7/step 3"
    , "  o  m2/m0:leave/INV/m2:inv0/assertion/hyp8/goal"
    , "  o  m2/m0:leave/INV/m2:inv0/assertion/hyp8/hypotheses"
    , "  o  m2/m0:leave/INV/m2:inv0/assertion/hyp8/relation"
    , "  o  m2/m0:leave/INV/m2:inv0/assertion/hyp8/step 1"
    , "  o  m2/m0:leave/INV/m2:inv0/assertion/hyp8/step 2"
    , "  o  m2/m0:leave/INV/m2:inv0/assertion/hyp8/step 3"
    , "  o  m2/m0:leave/INV/m2:inv0/main goal/goal"
    , "  o  m2/m0:leave/INV/m2:inv0/main goal/hypotheses"
    , "  o  m2/m0:leave/INV/m2:inv0/main goal/relation"
    , "  o  m2/m0:leave/INV/m2:inv0/main goal/step 1"
    , "  o  m2/m0:leave/INV/m2:inv0/main goal/step 2"
    , "  o  m2/m0:leave/INV/m2:inv0/main goal/step 3"
    , "  o  m2/m0:leave/INV/m2:inv0/new assumption"
    , "  o  m2/m0:leave/SAF/m2:saf1"
    , "  o  m2/m0:leave/SAF/m2:saf2"
    , "  o  m2/m0:leave/WD/GRD"
    , "  o  m2/m1:movein/C_SCH/delay/0/prog/m2:prog0/rhs/mi:c0"
    , "  o  m2/m1:movein/C_SCH/delay/0/saf/m0:enter/SAF/m1:movein"
    , "  o  m2/m1:movein/C_SCH/delay/0/saf/m0:leave/SAF/m1:movein"
    , " xxx m2/m1:movein/C_SCH/delay/0/saf/m1:movein/SAF/m1:movein"
    , "  o  m2/m1:movein/C_SCH/delay/0/saf/m1:moveout/SAF/m1:movein"
    , "  o  m2/m1:movein/FIS/loc@prime"
    , "  o  m2/m1:movein/INV/m2:inv0"
    , "  o  m2/m1:movein/SAF/m2:saf1"
    , "  o  m2/m1:movein/SAF/m2:saf2"
    , "  o  m2/m1:movein/SCH"
    , "  o  m2/m1:movein/SCH/b"
    , "  o  m2/m1:movein/WD/C_SCH"
    , "  o  m2/m1:movein/WD/GRD"
    , "  o  m2/m1:moveout/FIS/loc@prime"
    , "  o  m2/m1:moveout/F_SCH/replace/prog/m2:prog1/rhs/mo:f0"
    , "  o  m2/m1:moveout/INV/m2:inv0"
    , "  o  m2/m1:moveout/SAF/m2:saf1"
    , "  o  m2/m1:moveout/SAF/m2:saf2"
    , "  o  m2/m1:moveout/SCH/mo:g3"
    , "  o  m2/m1:moveout/WD/F_SCH"
    , "  o  m2/m1:moveout/WD/GRD"
    , "  o  m2/m2:prog0/LIVE/trading/lhs"
    , "  o  m2/m2:prog0/LIVE/trading/rhs"
    , "  o  m2/m2:prog0/PROG/WD/rhs"
    , "  o  m2/m2:prog1/LIVE/trading/lhs"
    , "  o  m2/m2:prog1/LIVE/trading/rhs"
    , "  o  m2/m2:prog1/PROG/WD/rhs"
    , "  o  m2/m2:prog2/LIVE/disjunction/lhs"
    , "  o  m2/m2:prog2/LIVE/disjunction/rhs"
    , "  o  m2/m2:prog2/PROG/WD/lhs"
    , "  o  m2/m2:prog2/PROG/WD/rhs"
    , "  o  m2/m2:prog3/LIVE/discharge/saf/lhs"
    , "  o  m2/m2:prog3/LIVE/discharge/saf/rhs"
    , "  o  m2/m2:prog3/LIVE/discharge/tr"
    , "  o  m2/m2:prog3/PROG/WD/lhs"
    , "  o  m2/m2:prog3/PROG/WD/rhs"
    , "  o  m2/m2:prog4/LIVE/monotonicity/lhs"
    , "  o  m2/m2:prog4/LIVE/monotonicity/rhs"
    , "  o  m2/m2:prog4/PROG/WD/lhs"
    , "  o  m2/m2:prog4/PROG/WD/rhs"
    , "  o  m2/m2:prog5/LIVE/disjunction/lhs"
    , "  o  m2/m2:prog5/LIVE/disjunction/rhs"
    , "  o  m2/m2:prog5/PROG/WD/lhs"
    , "  o  m2/m2:prog5/PROG/WD/rhs"
    , "  o  m2/m2:prog6/LIVE/discharge/saf/lhs"
    , "  o  m2/m2:prog6/LIVE/discharge/saf/rhs"
    , "  o  m2/m2:prog6/LIVE/discharge/tr"
    , "  o  m2/m2:prog6/PROG/WD/lhs"
    , "  o  m2/m2:prog6/PROG/WD/rhs"
    , "  o  m2/m2:saf1/SAF/WD/lhs"
    , "  o  m2/m2:saf1/SAF/WD/rhs"
    , "  o  m2/m2:saf2/SAF/WD/lhs"
    , "  o  m2/m2:saf2/SAF/WD/rhs"
    , "  o  m2/m2:tr0/TR/WD"
    , "  o  m2/m2:tr0/TR/WFIS/t/t@prime"
    , "  o  m2/m2:tr0/TR/m0:leave/EN"
    , "  o  m2/m2:tr0/TR/m0:leave/NEG"
    , "  o  m2/m2:tr1/TR/WD"
    , "  o  m2/m2:tr1/TR/WFIS/t/t@prime"
    , "  o  m2/m2:tr1/TR/leadsto/lhs"
    , "  o  m2/m2:tr1/TR/leadsto/rhs"
    , "  o  m2/m2:tr1/TR/m1:moveout/EN"
    , "  o  m2/m2:tr1/TR/m1:moveout/NEG"
    , "passed 99 / 100"
    ]

path0 :: FilePath
path0 = [path|Tests/train-station-ref.tex|]

path1 :: FilePath
path1 = [path|Tests/train-station-ref/main.tex|]

path1' :: FilePath
path1' = [path|Tests/train-station-ref/ref0.tex|]

path3 :: FilePath
path3 = [path|Tests/train-station-ref-err0.tex|]

result3 :: String
result3 = unlines
    [ "A cycle exists in the liveness proof"
    , "error 42:1:"
    , "\tProgress property p0 (refined in m0)"
    , ""
    , "error 51:1:"
    , "\tEvent evt (refined in m1)"
    , ""
    , ""
    ]

path4 :: FilePath
path4 = [path|Tests/train-station-ref-err1.tex|]

result4 :: String
result4 = unlines
    [ "error 31:1:"
    , "    Machine m0 refines a non-existant machine: mm"
    ]

-- parse :: FilePath -> IO String
-- parse path = do
--     r <- parse_machine path
--     return $ case r of
--         Right _ -> "ok"
--         Left xs -> unlines $ map report xs

path5 :: FilePath
path5 = [path|Tests/train-station-ref-err2.tex|]

result5 :: String
result5 = unlines
    [ "Theory imported multiple times"
    , "error 38:1:"
    , "\tsets"
    , ""
    , "error 88:1:"
    , "\tsets"
    , ""
    , "error 444:1:"
    , "\tsets"
    , ""
    , "error 445:1:"
    , "\tsets"
    , ""
    , ""
    , "Theory imported multiple times"
    , "error 89:1:"
    , "\tfunctions"
    , ""
    , "error 446:1:"
    , "\tfunctions"
    , ""
    , ""
    ]

case5 :: IO String
case5 = find_errors path5

case6 :: IO String
case6 = proof_obligation path0 "m1/m1:moveout/FIS/loc@prime" 1

result6 :: String
result6 = unlines
    [ "; m1/m1:moveout/FIS/loc@prime"
    , "(set-option :auto-config false)"
    , "(set-option :smt.timeout 3000)"
    , "(declare-datatypes (a) ( (Maybe (Just (fromJust a)) Nothing) ))"
    , "(declare-datatypes () ( (Null null) ))"
    , "(declare-datatypes (a b) ( (Pair (pair (first a) (second b))) ))"
    , "(declare-sort sl$Blk 0)"
    , "; comment: we don't need to declare the sort Bool"
    , "; comment: we don't need to declare the sort Int"
    , "; comment: we don't need to declare the sort Real"
    , "(declare-sort sl$Train 0)"
    , "(define-sort pfun (a b) (Array a (Maybe b)))"
    , "(define-sort set (a) (Array a Bool))"
    , "(declare-const ent sl$Blk)"
    , "(declare-const ext sl$Blk)"
    , "(declare-const in (set sl$Train))"
    , "(declare-const in@prime (set sl$Train))"
    , "(declare-const loc (pfun sl$Train sl$Blk))"
    , "(declare-const loc@prime (pfun sl$Train sl$Blk))"
    , "(declare-const plf (set sl$Blk))"
    , "(declare-const t sl$Train)"
    , "(declare-fun apply@@sl$Train@@sl$Blk"
    , "             ( (pfun sl$Train sl$Blk)"
    , "               sl$Train )"
    , "             sl$Blk)"
    , "(declare-fun card@@sl$Blk ( (set sl$Blk) ) Int)"
    , "(declare-fun card@@sl$Train ( (set sl$Train) ) Int)"
    , "(declare-fun dom@@sl$Train@@sl$Blk"
    , "             ( (pfun sl$Train sl$Blk) )"
    , "             (set sl$Train))"
    , "(declare-fun dom-rest@@sl$Train@@sl$Blk"
    , "             ( (set sl$Train)"
    , "               (pfun sl$Train sl$Blk) )"
    , "             (pfun sl$Train sl$Blk))"
    , "(declare-fun dom-subt@@sl$Train@@sl$Blk"
    , "             ( (set sl$Train)"
    , "               (pfun sl$Train sl$Blk) )"
    , "             (pfun sl$Train sl$Blk))"
    , "(declare-fun empty-fun@@sl$Train@@sl$Blk"
    , "             ()"
    , "             (pfun sl$Train sl$Blk))"
    , "(declare-fun finite@@sl$Blk ( (set sl$Blk) ) Bool)"
    , "(declare-fun finite@@sl$Train ( (set sl$Train) ) Bool)"
    , "(declare-fun injective@@sl$Train@@sl$Blk"
    , "             ( (pfun sl$Train sl$Blk) )"
    , "             Bool)"
    , "(declare-fun mk-fun@@sl$Train@@sl$Blk"
    , "             (sl$Train sl$Blk)"
    , "             (pfun sl$Train sl$Blk))"
    , "(declare-fun mk-set@@sl$Blk (sl$Blk) (set sl$Blk))"
    , "(declare-fun mk-set@@sl$Train (sl$Train) (set sl$Train))"
    , "(declare-fun ovl@@sl$Train@@sl$Blk"
    , "             ( (pfun sl$Train sl$Blk)"
    , "               (pfun sl$Train sl$Blk) )"
    , "             (pfun sl$Train sl$Blk))"
    , "(declare-fun ran@@sl$Train@@sl$Blk"
    , "             ( (pfun sl$Train sl$Blk) )"
    , "             (set sl$Blk))"
    , "(define-fun all@@sl$Blk"
    , "            ()"
    , "            (set sl$Blk)"
    , "            ( (as const (set sl$Blk))"
    , "              true ))"
    , "(define-fun all@@sl$Train"
    , "            ()"
    , "            (set sl$Train)"
    , "            ( (as const (set sl$Train))"
    , "              true ))"
    , "(define-fun compl@@sl$Blk"
    , "            ( (s1 (set sl$Blk)) )"
    , "            (set sl$Blk)"
    , "            ( (_ map not)"
    , "              s1 ))"
    , "(define-fun compl@@sl$Train"
    , "            ( (s1 (set sl$Train)) )"
    , "            (set sl$Train)"
    , "            ( (_ map not)"
    , "              s1 ))"
    , "(define-fun elem@@sl$Blk"
    , "            ( (x sl$Blk)"
    , "              (s1 (set sl$Blk)) )"
    , "            Bool"
    , "            (select s1 x))"
    , "(define-fun elem@@sl$Train"
    , "            ( (x sl$Train)"
    , "              (s1 (set sl$Train)) )"
    , "            Bool"
    , "            (select s1 x))"
    , "(define-fun empty-set@@sl$Blk"
    , "            ()"
    , "            (set sl$Blk)"
    , "            ( (as const (set sl$Blk))"
    , "              false ))"
    , "(define-fun empty-set@@sl$Train"
    , "            ()"
    , "            (set sl$Train)"
    , "            ( (as const (set sl$Train))"
    , "              false ))"
    , "(define-fun set-diff@@sl$Blk"
    , "            ( (s1 (set sl$Blk))"
    , "              (s2 (set sl$Blk)) )"
    , "            (set sl$Blk)"
    , "            (intersect s1 ( (_ map not) s2 )))"
    , "(define-fun set-diff@@sl$Train"
    , "            ( (s1 (set sl$Train))"
    , "              (s2 (set sl$Train)) )"
    , "            (set sl$Train)"
    , "            (intersect s1 ( (_ map not) s2 )))"
    , "(define-fun st-subset@@sl$Blk"
    , "            ( (s1 (set sl$Blk))"
    , "              (s2 (set sl$Blk)) )"
    , "            Bool"
    , "            (and (subset s1 s2) (not (= s1 s2))))"
    , "(define-fun st-subset@@sl$Train"
    , "            ( (s1 (set sl$Train))"
    , "              (s2 (set sl$Train)) )"
    , "            Bool"
    , "            (and (subset s1 s2) (not (= s1 s2))))"
    , "(define-fun sl$Blk"
    , "            ()"
    , "            (set sl$Blk)"
    , "            ( (as const (set sl$Blk))"
    , "              true ))"
    , "(define-fun sl$Train"
    , "            ()"
    , "            (set sl$Train)"
    , "            ( (as const (set sl$Train))"
    , "              true ))"
    , "(assert (forall ( (r (set sl$Blk)) )"
    , "                (! (=> (finite@@sl$Blk r) (<= 0 (card@@sl$Blk r)))"
    , "                   :pattern"
    , "                   ( (<= 0 (card@@sl$Blk r)) ))))"
    , "(assert (forall ( (r (set sl$Train)) )"
    , "                (! (=> (finite@@sl$Train r) (<= 0 (card@@sl$Train r)))"
    , "                   :pattern"
    , "                   ( (<= 0 (card@@sl$Train r)) ))))"
    , "(assert (forall ( (r (set sl$Blk)) )"
    , "                (! (= (= (card@@sl$Blk r) 0) (= r empty-set@@sl$Blk))"
    , "                   :pattern"
    , "                   ( (card@@sl$Blk r) ))))"
    , "(assert (forall ( (r (set sl$Train)) )"
    , "                (! (= (= (card@@sl$Train r) 0)"
    , "                      (= r empty-set@@sl$Train))"
    , "                   :pattern"
    , "                   ( (card@@sl$Train r) ))))"
    , "(assert (forall ( (x sl$Blk) )"
    , "                (! (= (card@@sl$Blk (mk-set@@sl$Blk x)) 1)"
    , "                   :pattern"
    , "                   ( (card@@sl$Blk (mk-set@@sl$Blk x)) ))))"
    , "(assert (forall ( (x sl$Train) )"
    , "                (! (= (card@@sl$Train (mk-set@@sl$Train x)) 1)"
    , "                   :pattern"
    , "                   ( (card@@sl$Train (mk-set@@sl$Train x)) ))))"
    , "(assert (forall ( (r (set sl$Blk)) )"
    , "                (! (= (= (card@@sl$Blk r) 1)"
    , "                      (exists ( (x sl$Blk) ) (and true (= r (mk-set@@sl$Blk x)))))"
    , "                   :pattern"
    , "                   ( (card@@sl$Blk r) ))))"
    , "(assert (forall ( (r (set sl$Train)) )"
    , "                (! (= (= (card@@sl$Train r) 1)"
    , "                      (exists ( (x sl$Train) )"
    , "                              (and true (= r (mk-set@@sl$Train x)))))"
    , "                   :pattern"
    , "                   ( (card@@sl$Train r) ))))"
    , "(assert (forall ( (r (set sl$Blk))"
    , "                  (r0 (set sl$Blk)) )"
    , "                (! (=> (= (intersect r r0) empty-set@@sl$Blk)"
    , "                       (= (card@@sl$Blk (union r r0))"
    , "                          (+ (card@@sl$Blk r) (card@@sl$Blk r0))))"
    , "                   :pattern"
    , "                   ( (card@@sl$Blk (union r r0)) ))))"
    , "(assert (forall ( (r (set sl$Train))"
    , "                  (r0 (set sl$Train)) )"
    , "                (! (=> (= (intersect r r0) empty-set@@sl$Train)"
    , "                       (= (card@@sl$Train (union r r0))"
    , "                          (+ (card@@sl$Train r) (card@@sl$Train r0))))"
    , "                   :pattern"
    , "                   ( (card@@sl$Train (union r r0)) ))))"
    , "(assert (= (dom@@sl$Train@@sl$Blk empty-fun@@sl$Train@@sl$Blk)"
    , "           empty-set@@sl$Train))"
    , "(assert (forall ( (f1 (pfun sl$Train sl$Blk)) )"
    , "                (! (= (ovl@@sl$Train@@sl$Blk f1 empty-fun@@sl$Train@@sl$Blk)"
    , "                      f1)"
    , "                   :pattern"
    , "                   ( (ovl@@sl$Train@@sl$Blk f1 empty-fun@@sl$Train@@sl$Blk) ))))"
    , "(assert (forall ( (f1 (pfun sl$Train sl$Blk)) )"
    , "                (! (= (ovl@@sl$Train@@sl$Blk empty-fun@@sl$Train@@sl$Blk f1)"
    , "                      f1)"
    , "                   :pattern"
    , "                   ( (ovl@@sl$Train@@sl$Blk empty-fun@@sl$Train@@sl$Blk f1) ))))"
    , "(assert (forall ( (x sl$Train)"
    , "                  (y sl$Blk) )"
    , "                (! (= (dom@@sl$Train@@sl$Blk (mk-fun@@sl$Train@@sl$Blk x y))"
    , "                      (mk-set@@sl$Train x))"
    , "                   :pattern"
    , "                   ( (dom@@sl$Train@@sl$Blk (mk-fun@@sl$Train@@sl$Blk x y)) ))))"
    , "(assert (forall ( (f1 (pfun sl$Train sl$Blk))"
    , "                  (f2 (pfun sl$Train sl$Blk))"
    , "                  (x sl$Train) )"
    , "                (! (=> (elem@@sl$Train x (dom@@sl$Train@@sl$Blk f2))"
    , "                       (= (apply@@sl$Train@@sl$Blk (ovl@@sl$Train@@sl$Blk f1 f2) x)"
    , "                          (apply@@sl$Train@@sl$Blk f2 x)))"
    , "                   :pattern"
    , "                   ( (apply@@sl$Train@@sl$Blk (ovl@@sl$Train@@sl$Blk f1 f2) x) ))))"
    , "(assert (forall ( (f1 (pfun sl$Train sl$Blk))"
    , "                  (f2 (pfun sl$Train sl$Blk))"
    , "                  (x sl$Train) )"
    , "                (! (=> (and (elem@@sl$Train x (dom@@sl$Train@@sl$Blk f1))"
    , "                            (not (elem@@sl$Train x (dom@@sl$Train@@sl$Blk f2))))"
    , "                       (= (apply@@sl$Train@@sl$Blk (ovl@@sl$Train@@sl$Blk f1 f2) x)"
    , "                          (apply@@sl$Train@@sl$Blk f1 x)))"
    , "                   :pattern"
    , "                   ( (apply@@sl$Train@@sl$Blk (ovl@@sl$Train@@sl$Blk f1 f2) x) ))))"
    , "(assert (forall ( (x sl$Train)"
    , "                  (y sl$Blk) )"
    , "                (! (= (apply@@sl$Train@@sl$Blk (mk-fun@@sl$Train@@sl$Blk x y) x)"
    , "                      y)"
    , "                   :pattern"
    , "                   ( (apply@@sl$Train@@sl$Blk (mk-fun@@sl$Train@@sl$Blk x y) x) ))))"
    , "(assert (forall ( (f1 (pfun sl$Train sl$Blk))"
    , "                  (s1 (set sl$Train))"
    , "                  (x sl$Train) )"
    , "                (! (=> (and (elem@@sl$Train x s1)"
    , "                            (elem@@sl$Train x (dom@@sl$Train@@sl$Blk f1)))"
    , "                       (= (apply@@sl$Train@@sl$Blk (dom-rest@@sl$Train@@sl$Blk s1 f1) x)"
    , "                          (apply@@sl$Train@@sl$Blk f1 x)))"
    , "                   :pattern"
    , "                   ( (apply@@sl$Train@@sl$Blk (dom-rest@@sl$Train@@sl$Blk s1 f1) x) ))))"
    , "(assert (forall ( (f1 (pfun sl$Train sl$Blk))"
    , "                  (s1 (set sl$Train))"
    , "                  (x sl$Train) )"
    , "                (! (=> (elem@@sl$Train x"
    , "                                       (set-diff@@sl$Train (dom@@sl$Train@@sl$Blk f1) s1))"
    , "                       (= (apply@@sl$Train@@sl$Blk (dom-subt@@sl$Train@@sl$Blk s1 f1) x)"
    , "                          (apply@@sl$Train@@sl$Blk f1 x)))"
    , "                   :pattern"
    , "                   ( (apply@@sl$Train@@sl$Blk (dom-subt@@sl$Train@@sl$Blk s1 f1) x) ))))"
    , "(assert (forall ( (f1 (pfun sl$Train sl$Blk))"
    , "                  (f2 (pfun sl$Train sl$Blk)) )"
    , "                (! (= (dom@@sl$Train@@sl$Blk (ovl@@sl$Train@@sl$Blk f1 f2))"
    , "                      (union (dom@@sl$Train@@sl$Blk f1)"
    , "                             (dom@@sl$Train@@sl$Blk f2)))"
    , "                   :pattern"
    , "                   ( (dom@@sl$Train@@sl$Blk (ovl@@sl$Train@@sl$Blk f1 f2)) ))))"
    , "(assert (forall ( (f1 (pfun sl$Train sl$Blk))"
    , "                  (s1 (set sl$Train)) )"
    , "                (! (= (dom@@sl$Train@@sl$Blk (dom-rest@@sl$Train@@sl$Blk s1 f1))"
    , "                      (intersect s1 (dom@@sl$Train@@sl$Blk f1)))"
    , "                   :pattern"
    , "                   ( (dom@@sl$Train@@sl$Blk (dom-rest@@sl$Train@@sl$Blk s1 f1)) ))))"
    , "(assert (forall ( (f1 (pfun sl$Train sl$Blk))"
    , "                  (s1 (set sl$Train)) )"
    , "                (! (= (dom@@sl$Train@@sl$Blk (dom-subt@@sl$Train@@sl$Blk s1 f1))"
    , "                      (set-diff@@sl$Train (dom@@sl$Train@@sl$Blk f1) s1))"
    , "                   :pattern"
    , "                   ( (dom@@sl$Train@@sl$Blk (dom-subt@@sl$Train@@sl$Blk s1 f1)) ))))"
    , "(assert (forall ( (f1 (pfun sl$Train sl$Blk))"
    , "                  (x sl$Train)"
    , "                  (y sl$Blk) )"
    , "                (! (= (and (elem@@sl$Train x (dom@@sl$Train@@sl$Blk f1))"
    , "                           (= (apply@@sl$Train@@sl$Blk f1 x) y))"
    , "                      (= (select f1 x) (Just y)))"
    , "                   :pattern"
    , "                   ( (elem@@sl$Train x (dom@@sl$Train@@sl$Blk f1))"
    , "                     (apply@@sl$Train@@sl$Blk f1 x)"
    , "                     (select f1 x)"
    , "                     (Just y) ))))"
    , "(assert (forall ( (f1 (pfun sl$Train sl$Blk))"
    , "                  (x sl$Train)"
    , "                  (x2 sl$Train)"
    , "                  (y sl$Blk) )"
    , "                (! (=> (not (= x x2))"
    , "                       (= (apply@@sl$Train@@sl$Blk (ovl@@sl$Train@@sl$Blk f1 (mk-fun@@sl$Train@@sl$Blk x y))"
    , "                                                   x2)"
    , "                          (apply@@sl$Train@@sl$Blk f1 x2)))"
    , "                   :pattern"
    , "                   ( (apply@@sl$Train@@sl$Blk (ovl@@sl$Train@@sl$Blk f1 (mk-fun@@sl$Train@@sl$Blk x y))"
    , "                                              x2) ))))"
    , "(assert (forall ( (f1 (pfun sl$Train sl$Blk))"
    , "                  (x sl$Train)"
    , "                  (y sl$Blk) )"
    , "                (! (= (apply@@sl$Train@@sl$Blk (ovl@@sl$Train@@sl$Blk f1 (mk-fun@@sl$Train@@sl$Blk x y))"
    , "                                               x)"
    , "                      y)"
    , "                   :pattern"
    , "                   ( (apply@@sl$Train@@sl$Blk (ovl@@sl$Train@@sl$Blk f1 (mk-fun@@sl$Train@@sl$Blk x y))"
    , "                                              x) ))))"
    , "(assert (= (ran@@sl$Train@@sl$Blk empty-fun@@sl$Train@@sl$Blk)"
    , "           empty-set@@sl$Blk))"
    , "(assert (forall ( (f1 (pfun sl$Train sl$Blk))"
    , "                  (y sl$Blk) )"
    , "                (! (= (elem@@sl$Blk y (ran@@sl$Train@@sl$Blk f1))"
    , "                      (exists ( (x sl$Train) )"
    , "                              (and true"
    , "                                   (and (elem@@sl$Train x (dom@@sl$Train@@sl$Blk f1))"
    , "                                        (= (apply@@sl$Train@@sl$Blk f1 x) y)))))"
    , "                   :pattern"
    , "                   ( (elem@@sl$Blk y (ran@@sl$Train@@sl$Blk f1)) ))))"
    , "(assert (forall ( (x sl$Train)"
    , "                  (y sl$Blk) )"
    , "                (! (= (ran@@sl$Train@@sl$Blk (mk-fun@@sl$Train@@sl$Blk x y))"
    , "                      (mk-set@@sl$Blk y))"
    , "                   :pattern"
    , "                   ( (ran@@sl$Train@@sl$Blk (mk-fun@@sl$Train@@sl$Blk x y)) ))))"
    , "(assert (forall ( (f1 (pfun sl$Train sl$Blk)) )"
    , "                (! (= (injective@@sl$Train@@sl$Blk f1)"
    , "                      (forall ( (x sl$Train)"
    , "                                (x2 sl$Train) )"
    , "                              (=> (and (elem@@sl$Train x (dom@@sl$Train@@sl$Blk f1))"
    , "                                       (elem@@sl$Train x2 (dom@@sl$Train@@sl$Blk f1)))"
    , "                                  (=> (= (apply@@sl$Train@@sl$Blk f1 x)"
    , "                                         (apply@@sl$Train@@sl$Blk f1 x2))"
    , "                                      (= x x2)))))"
    , "                   :pattern"
    , "                   ( (injective@@sl$Train@@sl$Blk f1) ))))"
    , "(assert (injective@@sl$Train@@sl$Blk empty-fun@@sl$Train@@sl$Blk))"
    , "(assert (forall ( (f1 (pfun sl$Train sl$Blk))"
    , "                  (x sl$Train) )"
    , "                (! (=> (elem@@sl$Train x (dom@@sl$Train@@sl$Blk f1))"
    , "                       (elem@@sl$Blk (apply@@sl$Train@@sl$Blk f1 x)"
    , "                                     (ran@@sl$Train@@sl$Blk f1)))"
    , "                   :pattern"
    , "                   ( (elem@@sl$Blk (apply@@sl$Train@@sl$Blk f1 x)"
    , "                                   (ran@@sl$Train@@sl$Blk f1)) ))))"
    , "(assert (forall ( (f1 (pfun sl$Train sl$Blk))"
    , "                  (s1 (set sl$Train))"
    , "                  (x sl$Train) )"
    , "                (! (=> (elem@@sl$Train x"
    , "                                       (set-diff@@sl$Train (dom@@sl$Train@@sl$Blk f1) s1))"
    , "                       (elem@@sl$Blk (apply@@sl$Train@@sl$Blk f1 x)"
    , "                                     (ran@@sl$Train@@sl$Blk (dom-subt@@sl$Train@@sl$Blk s1 f1))))"
    , "                   :pattern"
    , "                   ( (elem@@sl$Blk (apply@@sl$Train@@sl$Blk f1 x)"
    , "                                   (ran@@sl$Train@@sl$Blk (dom-subt@@sl$Train@@sl$Blk s1 f1))) ))))"
    , "(assert (forall ( (f1 (pfun sl$Train sl$Blk))"
    , "                  (s1 (set sl$Train))"
    , "                  (x sl$Train) )"
    , "                (! (=> (elem@@sl$Train x (intersect (dom@@sl$Train@@sl$Blk f1) s1))"
    , "                       (elem@@sl$Blk (apply@@sl$Train@@sl$Blk f1 x)"
    , "                                     (ran@@sl$Train@@sl$Blk (dom-rest@@sl$Train@@sl$Blk s1 f1))))"
    , "                   :pattern"
    , "                   ( (elem@@sl$Blk (apply@@sl$Train@@sl$Blk f1 x)"
    , "                                   (ran@@sl$Train@@sl$Blk (dom-rest@@sl$Train@@sl$Blk s1 f1))) ))))"
    , "(assert (forall ( (f1 (pfun sl$Train sl$Blk))"
    , "                  (x sl$Train)"
    , "                  (y sl$Blk) )"
    , "                (! (=> (and (elem@@sl$Train x (dom@@sl$Train@@sl$Blk f1))"
    , "                            (injective@@sl$Train@@sl$Blk f1))"
    , "                       (= (ran@@sl$Train@@sl$Blk (ovl@@sl$Train@@sl$Blk f1 (mk-fun@@sl$Train@@sl$Blk x y)))"
    , "                          (union (set-diff@@sl$Blk (ran@@sl$Train@@sl$Blk f1)"
    , "                                                   (mk-set@@sl$Blk (apply@@sl$Train@@sl$Blk f1 x)))"
    , "                                 (mk-set@@sl$Blk y))))"
    , "                   :pattern"
    , "                   ( (ran@@sl$Train@@sl$Blk (ovl@@sl$Train@@sl$Blk f1 (mk-fun@@sl$Train@@sl$Blk x y))) ))))"
    , "(assert (forall ( (f1 (pfun sl$Train sl$Blk))"
    , "                  (x sl$Train)"
    , "                  (y sl$Blk) )"
    , "                (! (=> (not (elem@@sl$Train x (dom@@sl$Train@@sl$Blk f1)))"
    , "                       (= (ran@@sl$Train@@sl$Blk (ovl@@sl$Train@@sl$Blk f1 (mk-fun@@sl$Train@@sl$Blk x y)))"
    , "                          (union (ran@@sl$Train@@sl$Blk f1) (mk-set@@sl$Blk y))))"
    , "                   :pattern"
    , "                   ( (ran@@sl$Train@@sl$Blk (ovl@@sl$Train@@sl$Blk f1 (mk-fun@@sl$Train@@sl$Blk x y))) ))))"
    , "(assert (forall ( (x sl$Blk)"
    , "                  (y sl$Blk) )"
    , "                (! (= (elem@@sl$Blk x (mk-set@@sl$Blk y)) (= x y))"
    , "                   :pattern"
    , "                   ( (elem@@sl$Blk x (mk-set@@sl$Blk y)) ))))"
    , "(assert (forall ( (x sl$Train)"
    , "                  (y sl$Train) )"
    , "                (! (= (elem@@sl$Train x (mk-set@@sl$Train y)) (= x y))"
    , "                   :pattern"
    , "                   ( (elem@@sl$Train x (mk-set@@sl$Train y)) ))))"
    , "(assert (forall ( (s1 (set sl$Blk))"
    , "                  (s2 (set sl$Blk)) )"
    , "                (! (=> (finite@@sl$Blk s1)"
    , "                       (finite@@sl$Blk (set-diff@@sl$Blk s1 s2)))"
    , "                   :pattern"
    , "                   ( (finite@@sl$Blk (set-diff@@sl$Blk s1 s2)) ))))"
    , "(assert (forall ( (s1 (set sl$Train))"
    , "                  (s2 (set sl$Train)) )"
    , "                (! (=> (finite@@sl$Train s1)"
    , "                       (finite@@sl$Train (set-diff@@sl$Train s1 s2)))"
    , "                   :pattern"
    , "                   ( (finite@@sl$Train (set-diff@@sl$Train s1 s2)) ))))"
    , "(assert (forall ( (s1 (set sl$Blk))"
    , "                  (s2 (set sl$Blk)) )"
    , "                (! (=> (and (finite@@sl$Blk s1) (finite@@sl$Blk s2))"
    , "                       (finite@@sl$Blk (union s1 s2)))"
    , "                   :pattern"
    , "                   ( (finite@@sl$Blk (union s1 s2)) ))))"
    , "(assert (forall ( (s1 (set sl$Train))"
    , "                  (s2 (set sl$Train)) )"
    , "                (! (=> (and (finite@@sl$Train s1) (finite@@sl$Train s2))"
    , "                       (finite@@sl$Train (union s1 s2)))"
    , "                   :pattern"
    , "                   ( (finite@@sl$Train (union s1 s2)) ))))"
    , "(assert (forall ( (x sl$Blk) )"
    , "                (! (finite@@sl$Blk (mk-set@@sl$Blk x))"
    , "                   :pattern"
    , "                   ( (finite@@sl$Blk (mk-set@@sl$Blk x)) ))))"
    , "(assert (forall ( (x sl$Train) )"
    , "                (! (finite@@sl$Train (mk-set@@sl$Train x))"
    , "                   :pattern"
    , "                   ( (finite@@sl$Train (mk-set@@sl$Train x)) ))))"
    , "(assert (finite@@sl$Blk empty-set@@sl$Blk))"
    , "(assert (finite@@sl$Train empty-set@@sl$Train))"
    , "(assert (forall ( (s1 (set sl$Blk))"
    , "                  (s2 (set sl$Blk)) )"
    , "                (! (=> (subset s1 s2)"
    , "                       (=> (finite@@sl$Blk s2) (finite@@sl$Blk s1)))"
    , "                   :pattern"
    , "                   ( (finite@@sl$Blk s2)"
    , "                     (finite@@sl$Blk s1) ))))"
    , "(assert (forall ( (s1 (set sl$Train))"
    , "                  (s2 (set sl$Train)) )"
    , "                (! (=> (subset s1 s2)"
    , "                       (=> (finite@@sl$Train s2) (finite@@sl$Train s1)))"
    , "                   :pattern"
    , "                   ( (finite@@sl$Train s2)"
    , "                     (finite@@sl$Train s1) ))))"
    , "(assert (not (exists ( (loc@prime (pfun sl$Train sl$Blk)) )"
    , "                     (and true"
    , "                          (= loc@prime"
    , "                             (ovl@@sl$Train@@sl$Blk loc (mk-fun@@sl$Train@@sl$Blk t ext)))))))"
    , "; SKIP:in"
    , "(assert (= in@prime in))"
    , "; asm0"
    , "(assert (and (not (elem@@sl$Blk ext plf)) (not (= ext ent))))"
    , "; asm1"
    , "(assert (forall ( (b sl$Blk) )"
    , "                (! (= (elem@@sl$Blk b sl$Blk)"
    , "                      (or (elem@@sl$Blk b plf) (= b ent) (= b ext)))"
    , "                   :pattern"
    , "                   ( (elem@@sl$Blk b sl$Blk) ))))"
    , "; asm2"
    , "(assert (exists ( (b sl$Blk) ) (and true (elem@@sl$Blk b plf))))"
    , "; asm3"
    , "(assert (not (elem@@sl$Blk ent plf)))"
    , "; c1"
    , "(assert (and (elem@@sl$Train t in)"
    , "             (elem@@sl$Blk (apply@@sl$Train@@sl$Blk loc t) plf)))"
    , "; inv0"
    , "(assert (= (dom@@sl$Train@@sl$Blk loc) in))"
    , "; mo:g1"
    , "(assert (elem@@sl$Train t in))"
    , "; mo:g2"
    , "(assert (elem@@sl$Blk (apply@@sl$Train@@sl$Blk loc t) plf))"
    , "(assert (not true))"
    , "(check-sat-using (or-else (then qe smt)"
    , "                          (then simplify smt)"
    , "                          (then skip smt)"
    , "                          (then (using-params simplify :expand-power true) smt)))"
    , "; m1/m1:moveout/FIS/loc@prime"
    ]
