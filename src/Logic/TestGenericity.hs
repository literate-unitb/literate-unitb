{-# LANGUAGE OverloadedStrings,TypeFamilies #-}
module Logic.TestGenericity where

    -- Modules
import Logic.Expr
import Logic.Expr.Const
import Logic.Proof ()
import Logic.Proof.Monad
import Logic.Theory

import Theories.SetTheory

import Z3.Z3

    -- Libraries
import Control.Lens hiding (lifted,Context,Const)
import Control.Monad

import Data.Map hiding ( map, union, member )
import Data.PartialOrd
import qualified Data.Set as S

import Test.QuickCheck
import Test.QuickCheck.AxiomaticClass
import Test.QuickCheck.Report ()

import Test.UnitTest

import Utilities.MapSyntax


left :: Type -> Type
left  = suffix_generics "1"

right :: Type -> Type
right = suffix_generics "2"

prop_yield_same_type :: (GType,GType) -> Maybe (GType,GType)
prop_yield_same_type (GType t0,GType t1) = 
        maybe (Just (GType t0, GType t1)) (const Nothing) (do
            un <- unify t0 t1
            let ct0 = instantiate un $ left t0
                ct1 = instantiate un $ right t1
            return (ct0 == ct1))

prop_unifying_yields_unified_type :: (GType, GType) -> Property
prop_unifying_yields_unified_type (GType t0, GType t1) = 
        match ==>
        maybe True (const False) (prop_yield_same_type (GType t0,GType t1))
    where
        match = unify t0 t1 /= Nothing

prop_common_symm :: GType -> GType -> Bool
prop_common_symm (GType t0) (GType t1) = common t0 t1 == common t1 t0 

counter_ex2_common_symm :: Bool
counter_ex2_common_symm = 
        prop_common_symm t0 t1
    where
        _a = gA
        pfun = fun_type
        t0 = GType $ array _a _a
        t1 = GType $ array _a (pfun (pfun _a int) real)


counter_ex_common_symm :: Bool
counter_ex_common_symm = prop_common_symm (GType t0) (GType t1)
    where
        _a = gA
        _b = gB
        _c = gC
        a = fromString'' "a"
        b = fromString'' "b"
        s2 = Sort (fromString'' "D") (fromString'' "D") 2
        _s2 = DefSort (fromString'' "E") (fromString'' "E") [a,b] $ array gA gB
        empty x y = Gen s2 [x,y]
        t0 = fun_type _b _a
        pfun = fun_type
        set = set_type
        t1 = (pfun (pfun int (pfun _c (set t3))) _c)
        t2 = (array (empty real (array (array bool _b) _c)) bool)
        t3 = (set (pfun real (set (set (array (pfun real t2) bool)))))


prop_type_unifies_with_self :: Type -> Bool
prop_type_unifies_with_self t = unify t t /= Nothing

mapping_acyclic :: (Type,Type) -> Maybe (Type,Type)
mapping_acyclic (t0,t1) =
        maybe (Just (t0,t1)) (const Nothing) (do
            un <- unify t0 t1
            return $ S.null (keysSet un `S.intersection` S.unions (map generics $ elems un)))

prop_type_mapping_acyclic :: (Type, Type) -> Property
prop_type_mapping_acyclic (t0,t1) = 
        match ==>
        maybe True (const False) (mapping_acyclic (t0,t1))
    where
        match = unify t0 t1 /= Nothing
        
check_prop :: Testable prop => prop -> IO Bool
check_prop p = do
        r <- quickCheckResult p
        case r of
            Success _ _ _ -> return True
            _             -> return False

newtype GType = GType { getType :: Type }
    deriving (Show,Eq)

instance Arbitrary GType where
    arbitrary = GType <$> oneof (
                [ return bool
                , return int
                , return real
                ] ++ concat (take 2 $ repeat
                [ do
                    t0 <- arbitrary
                    t1 <- arbitrary
                    return $ array t0 t1
                , oneof gen_prm
                , do
                    s  <- oneof sorts
                    ts <- case s of
                        RecordSort m -> 
                            replicateM (size m) arbitrary
                        Sort _ _ n -> 
                            replicateM n arbitrary
                        DefSort _ _ args _ -> 
                            replicateM (length args) arbitrary
                        IntSort -> 
                            return []
                        RealSort ->
                            return []
                        BoolSort -> 
                            return []
                        Datatype _ _ _ -> error "Type.arbitrary: impossible"
                    return $ Gen s ts
                , do
                    t <- arbitrary
                    return $ set_type t
                , do
                    t0 <- arbitrary
                    t1 <- arbitrary
                    return $ fun_type t0 t1
                ] ) )
        where
            sorts = map return
                [ z3Sort "A" "A" 0
                , z3Sort "B" "B" 1
                , z3Sort "C" "C" 1
                , z3Sort "D" "D" 2
                , z3DefSort "E" "E" ["a","b"] $ array gA gB
                , BoolSort
                , IntSort
                , RealSort
                ]
            gen_prm = map return
                [ gA
                , gB
                , gC
                ]
    shrink (GType (GENERIC _))  = []
    shrink (GType (VARIABLE _)) = []
    shrink (GType (Gen s ts)) = map GType ts ++ do
            ts <- mapM (shrink . GType) ts
            let t = Gen s $ map getType ts
            return $ GType t

unicity_counter_example :: [(Type,Type)]
unicity_counter_example = 
    [   (array real (Gen (z3Sort "C" "C" 1) [gB]),gB)
    ]

test_case :: TestCase
test_case = test

test :: TestCase
test = test_cases "genericity" (
        [ Case "unification, t0" (return $ unify gtype stype0) (Just $ fromList [(vC1,int), (vB1,real)])
        , Case "unification, t1" (return $ unify gtype stype1) (Just $ fromList [(vC1,set_type int), (vB1,real)])
        , Case "unification, t2" (return $ unify gtype stype2) Nothing
        , Case "unification, t3" (return $ unify gtype0 gtype1) (Just $ fromList [(vA1,set_type int), (vA2,real)])
        , Case "unification, t4" (return $ unify gtype1 gtype2) Nothing
        , Case "unification, t5" (return $ unify gtype0 gtype2) (Just $ fromList [(vA2,set_type real), (vA1,set_type $ set_type real)])
        , Case "unification, t6" (return $ unify int gC) (Just $ fromList [(vC2,int)])
        , Case "type instantiation" (return $ instantiate (fromList [(c, set_type int),(b,real)]) gtype) stype1
--        ,  Case "type inference 0" case2 result2
        , Case "type inference 1" case3 result3
--        , Case "type inference 2" case4 result4
                -- does not work because we cannot match 
                -- a generic parameter to a generic expression
        , Case "type inference 3" case5 result5
        , Case "type inference 4" case6 result6
        , Case "type inference 5" case7 result7
        , Case "instantiation of unified types is unique" (check_prop prop_unifying_yields_unified_type) True
        , Case "common type is symmetric" (check_prop prop_common_symm) True
        , StringCase "common type is symmetric (counter-example)" (return $ show counter_ex_common_symm) "True"
        , StringCase "common type is symmetric (counter-example 2)" (return $ show counter_ex2_common_symm) "True"
        ] ++
        map (\ce -> Case 
                "instantiation of unified types is unique (counter examples)" 
                (return $ prop_yield_same_type $ ce & each %~ GType) 
                Nothing
            ) unicity_counter_example ++ 
--        [ Case "types unify with self" (check_prop prop_type_unifies_with_self) True
        [ Case "type mapping are acyclic" (check_prop prop_type_mapping_acyclic) True
        , StringCase "one-point rule simplification on existentials" case8 result8
        , Case "axioms of type classes PreOrd and PartialOrd" case9 True
        , StringCase "Record expressions" case10 result10
        , StringCase "Record sets" case11 result11
        , Case "Record sets in Z3" case12 result12
        ] )
    where
        reserved x n = addSuffix ("@" ++ show n) (fromString'' x)
        vA1 = reserved "a" 1
        vA2 = reserved "a" 2
        vB1 = reserved "b" 1
        vC1 = reserved "c" 1
        vC2 = reserved "c" 2
        fun_sort = z3Sort "\\tfun" "fun" 2
        gtype    = Gen fun_sort [z3GENERIC "c", set_type $ z3GENERIC "b"]
        
        stype0   = Gen fun_sort [int, set_type real]
        stype1   = Gen fun_sort [set_type int, set_type real]
        stype2   = Gen fun_sort [set_type int, real]
        
        gtype0   = Gen fun_sort [gA, set_type real]
        gtype1   = Gen fun_sort [set_type int, set_type gA]
        gtype2   = Gen fun_sort [set_type gA, gA]

case3   :: IO Expr
result3 :: Expr
case5   :: IO Expr
result5 :: Expr
case6   :: IO Expr
result6 :: Expr
case3 = return $ specialize (fromList [(a,gB)]) $ FunApp union [x3,x4]
result3 = FunApp (mk_fun' [gB] "union" [set_type gB,set_type gB] $ set_type gB) [x3,x4] 
case5 = return $ p
result5 = q
case6 = return $ pp
result6 = qq

x1 :: Expr
x1 = Word $ z3Var "x1" (set_type int)
x2 :: Expr
x2 = Word $ z3Var "x2" (set_type int)
x3 :: Expr
x3 = Word $ z3Var "x3" (set_type $ set_type int)
x4 :: Expr
x4 = Word $ z3Var "x3" (set_type $ set_type int)
-- y  = Word $ Var "y" int
-- z  = Word $ Var "z" real
union :: Fun
union  = mk_fun' [gA] "union" [set_type gA,set_type gA] $ set_type gA

member :: Fun
member = mk_fun' [gA] "member" [gA, set_type gA] bool

a :: InternalName
a = fromString'' "a"
b :: InternalName
b = fromString'' "b"
c :: InternalName
c = fromString'' "c"

pp :: Expr
pp = FunApp member [FunApp union [x1,x2], specialize (fromList [(a,set_type gA)]) $ FunApp union [x3,x4]]

qq :: Expr
qq = FunApp member [FunApp union [x1,x2], FunApp (mk_fun' [set_type gA] "union" [set_type $ set_type gA,set_type $ set_type gA] $ set_type $ set_type gA) [x3,x4]]
p :: Expr
p = FunApp member [FunApp union [x1,x2], specialize (fromList [(a,set_type $ gA)]) $ FunApp union [x3,x4]]
q :: Expr
q = FunApp member [FunApp union [x1,x2], FunApp (mk_fun' [set_type gA] "union" [set_type $ set_type gA, set_type $ set_type gA] $ set_type $ set_type gA) [x3,x4]]

case7   :: IO ExprP
result7 :: ExprP
(case7, result7) = 
        ( return (x `zelem` zempty_set)
        , Right $ FunApp (mk_fun' [train] "elem" [train,set_type train] bool) [either (error "expecting right") id x,empty_set_of_train]
        )
    where
        train = Gen (z3Sort "\\train" "train" 0) []
        (x,_) = var "x" train
        empty_set_of_train = FunApp (mk_fun' [train] "empty-set" [] $ set_type train) []

result8 :: String
result8 = unlines
    [ "(and p q)"
    , "(and p (= 87 87))"
    , "(and (or (and p q)"
    , "         (and p (= 87 87))"
    , "         (and (= 7 7) q)"
    , "         (and (= 7 7) (= 7 87)))"
    , "     q)"
    , "(and (or (and p q)"
    , "         (and p (= 87 87))"
    , "         (and (= 7 7) q)"
    , "         (and (= 7 7) (= 7 87)))"
    , "     (= 87 87))"
    , "(and (= 7 7) q)"
    , "(and (= 7 7) (= 7 87))"
    ]

fromRight :: Either a b -> b
fromRight (Right x) = x
fromRight _ = error "expecting right"

case8 :: IO String
case8 = return $ unlines $ map pretty_print' $ disjuncts e'
    where
        (z,z_decl) = var "z" int
        z7  = mzint 7
        z87 = mzint 87
        (p,_) = var "p" bool
        (q,_) = var "q" bool
        e0 :: ExprP
        e0 = mzexists [z_decl] mztrue $ 
                            (p `mzor` (mzeq z z7)) 
                    `mzand` (q `mzor` (mzeq z z87))
        e = fromRight $ mzexists [z_decl] mztrue $ 
                            (p `mzor` e0 `mzor` (mzeq z z7)) 
                    `mzand` (q `mzor` (mzeq z z87))
        e' = one_point_rule e

case9 :: IO Bool
case9 = $(quickCheckClasses [''PreOrd,''PartialOrd])

case10 :: IO String
case10 = return $ z3_code $ runSequent $ do
        let t = record_type $ runMap' $ do
                x ## int
                b ## bool
            x = [smt|x|]
            b = [smt|b|]
        v1 <- declare "v1" t
        v2 <- declare "v2" t
        assume $ v1 .=. zrecord (x ## 7 >> b ## mztrue)
        assume $ v2 .=. zrec_update v1 (x ## 7)
        check $ v1 .=. v2

result10 :: String
result10 = unlines
    [ "(set-option :auto-config false)"
    , "(set-option :smt.timeout 3000)"
    , "(declare-datatypes (a) ( (Maybe (Just (fromJust a)) Nothing) ))"
    , "(declare-datatypes () ( (Null null) ))"
    , "(declare-datatypes (a1 a2) ( (Record-b-x (Record-b-x (b a1) (x a2))) ))"
    , "; comment: we don't need to declare the sort Bool"
    , "; comment: we don't need to declare the sort Int"
    , "(declare-const v1 (Record-b-x Bool Int))"
    , "(declare-const v2 (Record-b-x Bool Int))"
    , "(assert (= v1 (Record-b-x true 7)))"
    , "(assert (= v2 (Record-b-x (b v1) 7)))"
    , "(assert (not (= v1 v2)))"
    , "(check-sat-using (or-else (then qe smt)"
    , "                          (then simplify smt)"
    , "                          (then skip smt)"
    , "                          (then (using-params simplify :expand-power true) smt)))"
    ]

case11 :: IO String
case11 = return $ z3_code $ runSequent $ do
        include set_theory
        include basic_theory
        let t = record_type $ runMap' $ do
                x ## int
                b ## bool
            x = [smt|x|]
            b = [smt|b|]
        v1 <- declare "v1" t
        v2 <- declare "v2" t
        assume $ v1 .=. zrecord (x ## 7 >> b ## mztrue)
        assume $ v2 `zelem` zrecord_set (x ## zmk_set 7 >> b ## zcast (set_type bool) zset_all)
        check $ v1 .=. v2

result11 :: String
result11 = unlines
    [ "(set-option :auto-config false)"
    , "(set-option :smt.timeout 3000)"
    , "(declare-datatypes (a) ( (Maybe (Just (fromJust a)) Nothing) ))"
    , "(declare-datatypes () ( (Null null) ))"
    , "(declare-datatypes (a b) ( (Pair (pair (first a) (second b))) ))"
    , "(declare-datatypes (a1 a2) ( (Record-b-x (Record-b-x (b a1) (x a2))) ))"
    , "; comment: we don't need to declare the sort Bool"
    , "; comment: we don't need to declare the sort Int"
    , "(define-sort set (a) (Array a Bool))"
    , "(declare-const v1 (Record-b-x Bool Int))"
    , "(declare-const v2 (Record-b-x Bool Int))"
    , "(declare-fun const@Open@@Record-b-x@@Bool@@Int@Close@Open@@Record-b-x@@Bool@@Int@Close"
    , "             ( (Record-b-x Bool Int) )"
    , "             (Array (Record-b-x Bool Int) (Record-b-x Bool Int)))"
    , "(declare-fun finite@@Bool ( (set Bool) ) Bool)"
    , "(declare-fun finite@@Int ( (set Int) ) Bool)"
    , "(declare-fun finite@Open@@Record-b-x@@Bool@@Int@Close"
    , "             ( (set (Record-b-x Bool Int)) )"
    , "             Bool)"
    , "(declare-fun ident@Open@@Record-b-x@@Bool@@Int@Close"
    , "             ()"
    , "             (Array (Record-b-x Bool Int) (Record-b-x Bool Int)))"
    , "(declare-fun mk-set@@Bool (Bool) (set Bool))"
    , "(declare-fun mk-set@@Int (Int) (set Int))"
    , "(declare-fun mk-set@Open@@Record-b-x@@Bool@@Int@Close"
    , "             ( (Record-b-x Bool Int) )"
    , "             (set (Record-b-x Bool Int)))"
    , "(declare-fun set@Open@@Record-b-x@@Bool@@Int@Close@Open@@Record-b-x@@Bool@@Int@Close"
    , "             ( (set (Record-b-x Bool Int))"
    , "               (Array (Record-b-x Bool Int) (Record-b-x Bool Int)) )"
    , "             (set (Record-b-x Bool Int)))"
    , "(declare-fun @@lambda@@_0"
    , "             ( (set Bool)"
    , "               (set Int) )"
    , "             (set (Record-b-x Bool Int)))"
    , "(define-fun all@@Bool"
    , "            ()"
    , "            (set Bool)"
    , "            ( (as const (set Bool))"
    , "              true ))"
    , "(define-fun all@@Int () (set Int) ( (as const (set Int)) true ))"
    , "(define-fun all@Open@@Record-b-x@@Bool@@Int@Close"
    , "            ()"
    , "            (set (Record-b-x Bool Int))"
    , "            ( (as const (set (Record-b-x Bool Int)))"
    , "              true ))"
    , "(define-fun compl@@Bool"
    , "            ( (s1 (set Bool)) )"
    , "            (set Bool)"
    , "            ( (_ map not)"
    , "              s1 ))"
    , "(define-fun compl@@Int"
    , "            ( (s1 (set Int)) )"
    , "            (set Int)"
    , "            ( (_ map not)"
    , "              s1 ))"
    , "(define-fun compl@Open@@Record-b-x@@Bool@@Int@Close"
    , "            ( (s1 (set (Record-b-x Bool Int))) )"
    , "            (set (Record-b-x Bool Int))"
    , "            ( (_ map not)"
    , "              s1 ))"
    , "(define-fun elem@@Bool"
    , "            ( (x Bool)"
    , "              (s1 (set Bool)) )"
    , "            Bool"
    , "            (select s1 x))"
    , "(define-fun elem@@Int"
    , "            ( (x Int)"
    , "              (s1 (set Int)) )"
    , "            Bool"
    , "            (select s1 x))"
    , "(define-fun elem@Open@@Record-b-x@@Bool@@Int@Close"
    , "            ( (x (Record-b-x Bool Int))"
    , "              (s1 (set (Record-b-x Bool Int))) )"
    , "            Bool"
    , "            (select s1 x))"
    , "(define-fun empty-set@@Bool"
    , "            ()"
    , "            (set Bool)"
    , "            ( (as const (set Bool))"
    , "              false ))"
    , "(define-fun empty-set@@Int"
    , "            ()"
    , "            (set Int)"
    , "            ( (as const (set Int))"
    , "              false ))"
    , "(define-fun empty-set@Open@@Record-b-x@@Bool@@Int@Close"
    , "            ()"
    , "            (set (Record-b-x Bool Int))"
    , "            ( (as const (set (Record-b-x Bool Int)))"
    , "              false ))"
    , "(define-fun set-diff@@Bool"
    , "            ( (s1 (set Bool))"
    , "              (s2 (set Bool)) )"
    , "            (set Bool)"
    , "            (intersect s1 ( (_ map not) s2 )))"
    , "(define-fun set-diff@@Int"
    , "            ( (s1 (set Int))"
    , "              (s2 (set Int)) )"
    , "            (set Int)"
    , "            (intersect s1 ( (_ map not) s2 )))"
    , "(define-fun set-diff@Open@@Record-b-x@@Bool@@Int@Close"
    , "            ( (s1 (set (Record-b-x Bool Int)))"
    , "              (s2 (set (Record-b-x Bool Int))) )"
    , "            (set (Record-b-x Bool Int))"
    , "            (intersect s1 ( (_ map not) s2 )))"
    , "(define-fun st-subset@@Bool"
    , "            ( (s1 (set Bool))"
    , "              (s2 (set Bool)) )"
    , "            Bool"
    , "            (and (subset s1 s2) (not (= s1 s2))))"
    , "(define-fun st-subset@@Int"
    , "            ( (s1 (set Int))"
    , "              (s2 (set Int)) )"
    , "            Bool"
    , "            (and (subset s1 s2) (not (= s1 s2))))"
    , "(define-fun st-subset@Open@@Record-b-x@@Bool@@Int@Close"
    , "            ( (s1 (set (Record-b-x Bool Int)))"
    , "              (s2 (set (Record-b-x Bool Int))) )"
    , "            Bool"
    , "            (and (subset s1 s2) (not (= s1 s2))))"
    , "(assert (forall ( (x Bool)"
    , "                  (y Bool) )"
    , "                (! (= (elem@@Bool x (mk-set@@Bool y)) (= x y))"
    , "                   :pattern"
    , "                   ( (elem@@Bool x (mk-set@@Bool y)) ))))"
    , "(assert (forall ( (x Int)"
    , "                  (y Int) )"
    , "                (! (= (elem@@Int x (mk-set@@Int y)) (= x y))"
    , "                   :pattern"
    , "                   ( (elem@@Int x (mk-set@@Int y)) ))))"
    , "(assert (forall ( (x (Record-b-x Bool Int))"
    , "                  (y (Record-b-x Bool Int)) )"
    , "                (! (= (elem@Open@@Record-b-x@@Bool@@Int@Close x (mk-set@Open@@Record-b-x@@Bool@@Int@Close y))"
    , "                      (= x y))"
    , "                   :pattern"
    , "                   ( (elem@Open@@Record-b-x@@Bool@@Int@Close x (mk-set@Open@@Record-b-x@@Bool@@Int@Close y)) ))))"
    , "(assert (forall ( (r1 (set (Record-b-x Bool Int)))"
    , "                  (term (Array (Record-b-x Bool Int) (Record-b-x Bool Int)))"
    , "                  (y (Record-b-x Bool Int)) )"
    , "                (! (= (elem@Open@@Record-b-x@@Bool@@Int@Close y"
    , "                                                              (set@Open@@Record-b-x@@Bool@@Int@Close@Open@@Record-b-x@@Bool@@Int@Close r1 term))"
    , "                      (exists ( (x (Record-b-x Bool Int)) )"
    , "                              (and (elem@Open@@Record-b-x@@Bool@@Int@Close x r1)"
    , "                                   (= (select term x) y))))"
    , "                   :pattern"
    , "                   ( (elem@Open@@Record-b-x@@Bool@@Int@Close y"
    , "                                                             (set@Open@@Record-b-x@@Bool@@Int@Close@Open@@Record-b-x@@Bool@@Int@Close r1 term)) ))))"
    , "(assert (forall ( (r1 (set (Record-b-x Bool Int)))"
    , "                  (term (Array (Record-b-x Bool Int) (Record-b-x Bool Int)))"
    , "                  (y (Record-b-x Bool Int)) )"
    , "                (! (= (= (set@Open@@Record-b-x@@Bool@@Int@Close@Open@@Record-b-x@@Bool@@Int@Close r1 term)"
    , "                         (mk-set@Open@@Record-b-x@@Bool@@Int@Close y))"
    , "                      (forall ( (x (Record-b-x Bool Int)) )"
    , "                              (=> (elem@Open@@Record-b-x@@Bool@@Int@Close x r1)"
    , "                                  (= (select term x) y))))"
    , "                   :pattern"
    , "                   ( (set@Open@@Record-b-x@@Bool@@Int@Close@Open@@Record-b-x@@Bool@@Int@Close r1 term)"
    , "                     (mk-set@Open@@Record-b-x@@Bool@@Int@Close y) ))))"
    , "(assert (forall ( (s1 (set Bool))"
    , "                  (s2 (set Bool)) )"
    , "                (! (=> (finite@@Bool s1)"
    , "                       (finite@@Bool (set-diff@@Bool s1 s2)))"
    , "                   :pattern"
    , "                   ( (finite@@Bool (set-diff@@Bool s1 s2)) ))))"
    , "(assert (forall ( (s1 (set Int))"
    , "                  (s2 (set Int)) )"
    , "                (! (=> (finite@@Int s1)"
    , "                       (finite@@Int (set-diff@@Int s1 s2)))"
    , "                   :pattern"
    , "                   ( (finite@@Int (set-diff@@Int s1 s2)) ))))"
    , "(assert (forall ( (s1 (set (Record-b-x Bool Int)))"
    , "                  (s2 (set (Record-b-x Bool Int))) )"
    , "                (! (=> (finite@Open@@Record-b-x@@Bool@@Int@Close s1)"
    , "                       (finite@Open@@Record-b-x@@Bool@@Int@Close (set-diff@Open@@Record-b-x@@Bool@@Int@Close s1 s2)))"
    , "                   :pattern"
    , "                   ( (finite@Open@@Record-b-x@@Bool@@Int@Close (set-diff@Open@@Record-b-x@@Bool@@Int@Close s1 s2)) ))))"
    , "(assert (forall ( (s1 (set Bool))"
    , "                  (s2 (set Bool)) )"
    , "                (! (=> (and (finite@@Bool s1) (finite@@Bool s2))"
    , "                       (finite@@Bool (union s1 s2)))"
    , "                   :pattern"
    , "                   ( (finite@@Bool (union s1 s2)) ))))"
    , "(assert (forall ( (s1 (set Int))"
    , "                  (s2 (set Int)) )"
    , "                (! (=> (and (finite@@Int s1) (finite@@Int s2))"
    , "                       (finite@@Int (union s1 s2)))"
    , "                   :pattern"
    , "                   ( (finite@@Int (union s1 s2)) ))))"
    , "(assert (forall ( (s1 (set (Record-b-x Bool Int)))"
    , "                  (s2 (set (Record-b-x Bool Int))) )"
    , "                (! (=> (and (finite@Open@@Record-b-x@@Bool@@Int@Close s1)"
    , "                            (finite@Open@@Record-b-x@@Bool@@Int@Close s2))"
    , "                       (finite@Open@@Record-b-x@@Bool@@Int@Close (union s1 s2)))"
    , "                   :pattern"
    , "                   ( (finite@Open@@Record-b-x@@Bool@@Int@Close (union s1 s2)) ))))"
    , "(assert (forall ( (x Bool) )"
    , "                (! (finite@@Bool (mk-set@@Bool x))"
    , "                   :pattern"
    , "                   ( (finite@@Bool (mk-set@@Bool x)) ))))"
    , "(assert (forall ( (x Int) )"
    , "                (! (finite@@Int (mk-set@@Int x))"
    , "                   :pattern"
    , "                   ( (finite@@Int (mk-set@@Int x)) ))))"
    , "(assert (forall ( (x (Record-b-x Bool Int)) )"
    , "                (! (finite@Open@@Record-b-x@@Bool@@Int@Close (mk-set@Open@@Record-b-x@@Bool@@Int@Close x))"
    , "                   :pattern"
    , "                   ( (finite@Open@@Record-b-x@@Bool@@Int@Close (mk-set@Open@@Record-b-x@@Bool@@Int@Close x)) ))))"
    , "(assert (finite@@Bool empty-set@@Bool))"
    , "(assert (finite@@Int empty-set@@Int))"
    , "(assert (finite@Open@@Record-b-x@@Bool@@Int@Close empty-set@Open@@Record-b-x@@Bool@@Int@Close))"
    , "(assert (forall ( (s1 (set Bool))"
    , "                  (s2 (set Bool)) )"
    , "                (! (=> (subset s1 s2)"
    , "                       (=> (finite@@Bool s2) (finite@@Bool s1)))"
    , "                   :pattern"
    , "                   ( (finite@@Bool s2)"
    , "                     (finite@@Bool s1) ))))"
    , "(assert (forall ( (s1 (set Int))"
    , "                  (s2 (set Int)) )"
    , "                (! (=> (subset s1 s2)"
    , "                       (=> (finite@@Int s2) (finite@@Int s1)))"
    , "                   :pattern"
    , "                   ( (finite@@Int s2)"
    , "                     (finite@@Int s1) ))))"
    , "(assert (forall ( (s1 (set (Record-b-x Bool Int)))"
    , "                  (s2 (set (Record-b-x Bool Int))) )"
    , "                (! (=> (subset s1 s2)"
    , "                       (=> (finite@Open@@Record-b-x@@Bool@@Int@Close s2)"
    , "                           (finite@Open@@Record-b-x@@Bool@@Int@Close s1)))"
    , "                   :pattern"
    , "                   ( (finite@Open@@Record-b-x@@Bool@@Int@Close s2)"
    , "                     (finite@Open@@Record-b-x@@Bool@@Int@Close s1) ))))"
    , "(assert (forall ( (r1 (set (Record-b-x Bool Int))) )"
    , "                (! (= (set@Open@@Record-b-x@@Bool@@Int@Close@Open@@Record-b-x@@Bool@@Int@Close r1 ident@Open@@Record-b-x@@Bool@@Int@Close)"
    , "                      r1)"
    , "                   :pattern"
    , "                   ( (set@Open@@Record-b-x@@Bool@@Int@Close@Open@@Record-b-x@@Bool@@Int@Close r1 ident@Open@@Record-b-x@@Bool@@Int@Close) ))))"
    , "(assert (forall ( (x (Record-b-x Bool Int))"
    , "                  (y (Record-b-x Bool Int)) )"
    , "                (! (= (select (const@Open@@Record-b-x@@Bool@@Int@Close@Open@@Record-b-x@@Bool@@Int@Close x)"
    , "                              y)"
    , "                      x)"
    , "                   :pattern"
    , "                   ( (select (const@Open@@Record-b-x@@Bool@@Int@Close@Open@@Record-b-x@@Bool@@Int@Close x)"
    , "                             y) ))))"
    , "(assert (forall ( (x (Record-b-x Bool Int)) )"
    , "                (! (= (select ident@Open@@Record-b-x@@Bool@@Int@Close x)"
    , "                      x)"
    , "                   :pattern"
    , "                   ( (select ident@Open@@Record-b-x@@Bool@@Int@Close x) ))))"
    , "(assert (= v1 (Record-b-x true 7)))"
    , "(assert (elem@Open@@Record-b-x@@Bool@@Int@Close v2"
    , "                                                (set@Open@@Record-b-x@@Bool@@Int@Close@Open@@Record-b-x@@Bool@@Int@Close (@@lambda@@_0 all@@Bool (mk-set@@Int 7))"
    , "                                                                                                                         ident@Open@@Record-b-x@@Bool@@Int@Close)))"
    , "(assert (forall ( (@@fv@@_0 (set Bool))"
    , "                  (@@fv@@_1 (set Int))"
    , "                  (@@bv@@_0 (Record-b-x Bool Int)) )"
    , "                (! (= (elem@Open@@Record-b-x@@Bool@@Int@Close @@bv@@_0 (@@lambda@@_0 @@fv@@_0 @@fv@@_1))"
    , "                      (and (elem@@Bool (b @@bv@@_0) @@fv@@_0)"
    , "                           (elem@@Int (x @@bv@@_0) @@fv@@_1)))"
    , "                   :pattern"
    , "                   ( (elem@Open@@Record-b-x@@Bool@@Int@Close @@bv@@_0 (@@lambda@@_0 @@fv@@_0 @@fv@@_1)) ))))"
    , "(assert (not (= v1 v2)))"
    , "(check-sat-using (or-else (then qe smt)"
    , "                          (then simplify smt)"
    , "                          (then skip smt)"
    , "                          (then (using-params simplify :expand-power true) smt)))"
    ]

case12 :: IO Validity
case12 = discharge ("case12") $ runSequent $ do
        include set_theory
        include basic_theory
        let t = record_type $ runMap' $ do
                x ## int
                b ## bool
            x = [smt|x|]
            b = [smt|b|]
        v1 <- declare "v1" t
        v2 <- declare "v2" t
        assume $ v1 .=. zrecord (x ## 7 >> b ## mztrue)
        assume $ v2 `zelem` zrecord_set (x ## zmk_set 7 >> b ## zmk_set mztrue)
        check $ v1 .=. v2

result12 :: Validity
result12 = Valid
