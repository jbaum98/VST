Require Import reify.
Require Import floyd.proofauto.
Require Import progs.list_dt.
Require Import reverse_defs.
Require Import mccancel.
Require Import set_reif.
(*Require Import MirrorCore.STac.STac.
Require Import MirrorCore.RTac.Core.
Require Import MirrorCore.RTac.RTac.
Require Import funcs.
Import MirrorCore.Lambda.Expr.*)
Require Import MirrorCore.Lemma.
Require Import MirrorCharge.RTac.ReifyLemma.
Require Import MirrorCharge.RTac.Apply.
Require Import MirrorCharge.RTac.EApply.
Require Import MirrorCharge.RTac.Instantiate.
Require Import MirrorCore.Lambda.ExprUnify_simul.
Require Import MirrorCharge.RTac.Intro.
Import MirrorCore.RTac.Repeat.
Import MirrorCore.RTac.Then.
Import MirrorCore.RTac.Try.
Import MirrorCore.RTac.First.
Require Import local2list.

Local Open Scope logic.

Existing Instance NullExtension.Espec.

Ltac reify_expr_tac :=
match goal with
| [ |- ?trm] => reify_vst trm
end.

Definition lift_eq_val2  (a b : environ -> val) : environ -> Prop := `eq a b.
Definition lift_eq_val a (b : environ -> val) : environ -> Prop := `(eq a) b.
Definition sp (s : mpred) : environ -> mpred:= `s.

Ltac replace_lift :=
repeat
match goal with
| [ |- context [`eq ?A ?B]] => change (`eq A B) with (lift_eq_val2 A B)
| [ |- context [`(eq ?A) ?B]] => change (`(eq A) B) with (lift_eq_val A B)
end;
repeat
match goal with
| [ |- context [`?S]] => change (`S) with (sp S)
end.

Require Import floyd.local2ptree.


Lemma LocalD_to_localD : forall P R t l X,
PROPx (P) (LOCALx (LocalD t l X) (SEPx (R))) |--
PROPx (P) (LOCALx (localD t l) (SEPx (R))).
Proof.
intros. entailer.
apply prop_right.
unfold localD. 
repeat rewrite LocalD_app_eq in *.
unfold LocalD_app in *.
repeat rewrite fold_right_conj in *.
intuition. simpl. apply I.
Qed.

Ltac do_local2ptree := eapply semax_pre0; [ eapply local2ptree_soundness; repeat constructor | ]; eapply semax_pre0; [ apply LocalD_to_localD | ].

Definition my_lemma := lemma typ (ExprCore.expr typ func) (ExprCore.expr typ func).

Check update_tycon.

Lemma semax_seq_reif c1 c2 : forall  (Espec : OracleKind) 
         (P : environ -> mpred)  (P' : environ -> mpred)
          (Q : ret_assert) (Delta : tycontext) ,
       @semax Espec Delta P c1 (normal_ret_assert P') ->
       @semax Espec (update_tycon Delta c1) P' c2 Q ->
       @semax Espec Delta P (Ssequence c1 c2) Q.
intros.
eapply semax_seq'; eauto.
Qed.


Definition skip_lemma : my_lemma.
reify_lemma reify_vst 
@semax_skip.
Defined. 


Definition seq_lemma (s1 s2: statement)  : my_lemma.
reify_lemma reify_vst (semax_seq_reif s1 s2).
Defined.

Definition set_lemma (id : positive) (e : Clight.expr) (v : val) 
         (ls : PTree.t val) (vs : PTree.t (type * val))  : my_lemma.
reify_lemma reify_vst (semax_set_localD id e v ls vs).
Defined.


Definition INTROS := (REPEAT 10 (INTRO typ func subst)).

Definition APPLY_SKIP :=  (APPLY typ func subst skip_lemma).

Definition run_tac (t: rtac typ (ExprCore.expr typ func) subst) e := 
  t CTop (SubstI.empty (expr := ExprCore.expr typ func)) e.

Definition APPLY_SEQ' s1 s2 := (EAPPLY typ func subst (seq_lemma s1 s2)).

Definition APPLY_SEQ_SKIP s1 s2:= (THEN  (EAPPLY typ func subst (seq_lemma s1 s2)) (THEN (INSTANTIATE typ func subst) (TRY APPLY_SKIP))).

Definition APPLY_SEQ s1 s2 k := (THEN  (EAPPLY typ func subst (seq_lemma s1 s2)) k).

Definition APPLY_SET' id e v ls vs :=
EAPPLY typ func subst (set_lemma id e v ls vs).


(*Definition get_comp e :=
match e with*)

Fixpoint get_first_statement (s : expr typ func) := 
match s with
| (Inj (inr (Smx (fstatement stmt)))) => stmt
| App e1 e2 => match (get_first_statement e1)  with
                   | Sskip => (get_first_statement e2)
                   | stmt => stmt
               end
| Abs _ e => get_first_statement e
| _ => Sskip
end.

Fixpoint symexe' s :=
match s with 
| Sskip => APPLY_SKIP
| Ssequence s1 s2 => APPLY_SEQ s1 s2 (FIRST ((symexe' s1) :: (symexe' s2) :: nil)) 
| _ => APPLY_SKIP
end.

Definition symexe_tac (e : expr typ func) :=
THEN INTROS (symexe' (get_first_statement e)).

Definition symexe e:=
run_tac (symexe_tac e) e.

Lemma skip_triple : forall p e,
@semax e empty_tycontext
     p
      Sskip 
     (normal_ret_assert p).
Proof. 
Time reify_expr_tac.
Time Eval vm_compute in  run_tac (symexe_tac e) e.
Abort.

Fixpoint lots_of_skips n :=
match n with 
| O => Sskip
| S n' => Ssequence Sskip (lots_of_skips n')
end.

Lemma seq_triple : forall p es,
@semax es empty_tycontext p (Ssequence Sskip Sskip) (normal_ret_assert p).
Proof.
reify_expr_tac.
Time Eval vm_compute in  run_tac (symexe_tac e) e.
Abort.

Lemma seq_triple_lots : forall p es,
@semax es empty_tycontext p (lots_of_skips 10) (normal_ret_assert p).
Proof.
reify_expr_tac.
Time Eval vm_compute in  run_tac (symexe_tac e) e.
Abort.

Ltac pull_sep_lift R :=
match R with
| ((`?H) :: ?T) => let rest := pull_sep_lift T in constr:(cons H rest)
| (@nil _) => constr:(@nil mpred)
end.

Ltac extract_sep_lift_semax :=
  match goal with
      [ |- semax _ (*(PROP (?P1) (LOCALx ?Q1 SEP (?R1)))*) 
                 (PROPx ?P1 (LOCALx ?Q1 (SEPx ?R1))) _ 
                 (normal_ret_assert (PROPx ?P2 (LOCALx ?Q2 (SEPx ?R2))))] =>
      let R1' := pull_sep_lift R1 in
      let R2' := pull_sep_lift R2 in
      try (change (PROPx (P1) (LOCALx Q1 (SEPx (R1)))) 
      with (assertD nil Q1 R1'));
      try  (change (PROPx (P2) (LOCALx Q2 (SEPx (R2)))) 
      with (assertD nil Q2 R2'))
end.

Ltac do_local2list := erewrite local2list_soundness; [ | repeat constructor].


Fixpoint extract_semax (e : expr typ func) : expr typ func :=
match e with
| App (App (App (App (App (Inj (inr (Smx fsemax))) _) _) _) _) _ => e
| App _ e 
| Abs _ e => extract_semax e
| _ => Inj (inr (Value fVundef))
end.
Goal forall n (p : ident) (e1 e2: val), n = [(_p, (Tvoid, e1)); (_p, (Tvoid, e2))].
intros. reify_vst [(_p, (Tvoid, e1))(*; (_p, (Tvoid, e2))*)].

Goal forall n (p : ident) (e1 e2: val), n = [(_p, e1); (_p,  e2)].
intros. 
 reify_vst [(_p, e1); (_p, e2)].

Goal forall n, n = [_p].
reify_vst [(_p, _p); (_p, _p)].

 
Definition and_eq (v1 v2 p: expr typ func) t  : expr typ func :=
App (App (Inj (inr (Other fand))) (App (App (Inj (inr (Other (feq t)))) v1) v2)) p.

Fixpoint local2ptree_reif' (e : expr typ func) (v :(PTree.t (expr typ func))) (prp : (expr typ func)) :
  option ((PTree.t (expr typ func)) * ((expr typ func))) :=
match e with
| App (App (Inj (inr (Lst (fcons (typrod tyident tyval)))))
             (App
                (App (Inj (inr (Lst (fpair tyident tyval))))
                     (Inj (inr (Const (fPos p))))) (val))) tl =>
  (*  (p, val)::tl *) 
  match PTree.get p v with 
      | Some ex => local2ptree_reif' tl v (and_eq ex val prp tyval)
      | None => local2ptree_reif' tl ((PTree.set p val v)) prp
  end
| Inj (inr (Lst (fnil (typrod tyident tyval)))) (*nil*) => Some (v, prp)
| _ => None
end.                                               

Definition ctyp t : expr typ func:= Inj (inr (Const (fCtype t))). 

Fixpoint vars2ptree_reif' (e : expr typ func) (v : PTree.t (type * (expr typ func))) (prp : (expr typ func)) : option ((PTree.t (type * (expr typ func))) * (expr typ func)) :=
match e with
| App
    (App
       (Inj (inr (Lst (fcons (typrod tyident (typrod tyc_type tyval))))))
       (App
          (App (Inj (inr (Lst (fpair tyident (typrod tyc_type tyval)))))
               (Inj (inr (Const (fPos p)))))
          (App
             (App (Inj (inr (Lst (fpair tyc_type tyval))))
                  (Inj (inr (Const (fCtype typ))))) (val)))) tl =>
  (*  (p, (typ, val))::tl *) 
  match PTree.get p v with 
      | Some (typ2, ex) => vars2ptree_reif' tl v (and_eq (ctyp typ) (ctyp typ2) 
                                                          (and_eq ex val prp tyval) tyc_type)
      | None => vars2ptree_reif' tl ((PTree.set p (typ, val) v)) prp
  end
| Inj (inr (Lst (fnil (typrod tyident tyval)))) (*nil*) => Some (v, prp)
| _ => None
end.
  
Definition local2ptree_reif e := local2ptree_reif' e (PTree.empty (expr typ func)) (Inj (inr (Other fTrue))).

Definition vars2ptree_reif e := vars2ptree_reif' e (PTree.empty (type * (expr typ func))) (Inj (inr (Other fTrue))).


Lemma set_triple :
forall sh p (contents : list val),
semax Delta2
     (PROP  ()
      LOCAL  (`(eq p) (eval_id _p))  SEP  (`(lseg LS sh contents p nullval)))
     (Ssequence (Sset _w (Ecast (Econst_int (Int.repr 0) tint) (tptr tvoid)))
        Sskip) 
(normal_ret_assert (PROP  ()
      LOCAL  (`(eq (Vint (Int.repr 0))) (eval_id _w); 
      `(eq p) (eval_id _p))  SEP  (`(lseg LS sh contents p nullval)))).
Proof.
intros.
do_local2list.
extract_sep_lift_semax.
revert sh.
reify_expr_tac.
reify_vst (forall s1 s2 n, Ssequence s1 s2 = n).
extract_sep_lift_semax.
replace_lift.
revert sh contents.
reify_expr_tac.





 
Lemma skip_triple_2 :forall p contents sh,
semax Delta2
     (PROP  ()
      LOCAL  (`(eq p) (eval_id _p))  SEP  (`(lseg LS sh contents p nullval)))
     Sskip 
     (normal_ret_assert (PROP  ()
      LOCAL  (`(eq p) (eval_id _p))  SEP  (`(lseg LS sh contents p nullval)))).
Proof.
intros.
do_local2ptree.
extract_sep_lift_semax.
replace_lift.
reify_expr_tac.
Time Eval vm_compute in run_tac (symexe_tac e) e.
revert p contents sh. intro p.
reify_vst (
forall  (contents : list (elemtype LS)) (sh : share),
   semax Delta2
     (PROP  ()
      (LOCALx
         (LocalD (PTree.set _p p (PTree.empty val))
            (PTree.empty (type * val)) [])
         SEP  (sp (lseg LS sh contents p nullval))))
     (Ssequence (Sset _w (Ecast (Econst_int (Int.repr 0) tint) (tptr tvoid)))
        Sskip)
     (normal_ret_assert
        (PROP  ()
         LOCAL  (lift_eq_val p (eval_id _p))
         SEP  (sp (lseg LS sh contents p nullval))))).
reify_expr_tac.
reify_vst ((PROP  ()
      (LOCALx
         (LocalD (PTree.set _p p (PTree.empty val))
            (PTree.empty (type * val)) [])
         SEP  (sp (lseg LS sh contents p nullval))))).
reify_vst (LocalD (PTree.set _p p (PTree.empty val))
            (PTree.empty (type * val)) []).

reify_vst (forall n , n = (PTree.empty val)).
PTree.set _p p (PTree.empty val)).
         (LocalD (PTree.set _p p (PTree.empty val))
            (PTree.empty (type * val)) [])).
reify_vst (forall (p : val) (contents : list (elemtype LS)) (sh : share),
   semax Delta2
             (PROP  ()
         LOCAL  (lift_eq_val p (eval_id _p))
         SEP  (sp (lseg LS sh contents p nullval)))
     (Ssequence (Sset _w (Ecast (Econst_int (Int.repr 0) tint) (tptr tvoid)))
        Sskip)
     (normal_ret_assert
        (PROP  ()
         LOCAL  (lift_eq_val p (eval_id _p))
         SEP  (sp (lseg LS sh contents p nullval))))).
reify_expr_tac.

Lemma triple : forall p contents sh,
semax Delta2
     (PROP  ()
      LOCAL  (`(eq p) (eval_id _p))  SEP  (`(lseg LS sh contents p nullval)))
     (Ssequence (Sset _w (Ecast (Econst_int (Int.repr 0) tint) (tptr tvoid)))
        Sskip) 
(normal_ret_assert (PROP  ()
      LOCAL  (`(eq (Vint (Int.repr 0))) (eval_id _w); 
      `(eq p) (eval_id _p))  SEP  (`(lseg LS sh contents p nullval)))).
Proof.
intros.
do_local2ptree.
replace_lift.
eapply semax_seq.
reify_expr_tac.
reify_vst (semax Delta2
     (PROP  ()
      (LOCALx
         (LocalD (PTree.set _p p (PTree.empty val))
            (PTree.empty (type * val)) [tc_environ Delta2])
         SEP  (`(lseg LS sh contents p nullval))))
     (Ssequence (Sset _w (Ecast (Econst_int (Int.repr 0) tint) (tptr tvoid)))
        Sskip)
     (normal_ret_assert
        (PROP  ()
         LOCAL  (`(eq (Vint (Int.repr 0))) (eval_id _w);
         `(eq p) (eval_id _p))  SEP  (`(lseg LS sh contents p nullval))))).
reify_expr_tac.


Goal forall sh i cts contents t0 y, 
exists a, exists b, exists c,
   PROP  ()
   LOCAL  (tc_environ Delta; `(eq t0) (eval_id _t);
   `(eq (Vint (Int.sub (sum_int contents) (sum_int (i :: cts)))))
     (eval_id _s))
   SEP 
   (`(field_at sh t_struct_list (_head :: nil) (Vint i))
      (fun _ : lift_S (LiftEnviron mpred) => t0);
   `(field_at sh t_struct_list (_tail :: nil)
       (valinject (nested_field_type2 t_struct_list (_tail :: nil)) y))
     (fun _ : lift_S (LiftEnviron mpred) => t0);
   `(lseg LS sh (map Vint cts)) `y `nullval; TT)
   |-- local
         (tc_lvalue Delta
            (Efield (Ederef (Etempvar _t (tptr t_struct_list)) t_struct_list)
               _head tint)) && local `(tc_val tint a) &&
       (`(field_at b t_struct_list (_head :: nil) c)
          (eval_lvalue
             (Ederef (Etempvar _t (tptr t_struct_list)) t_struct_list)) * TT).
Proof.
intros.
eexists. eexists. eexists.
Admitted.

Instance x : RSym func := _.
Print x.

Definition RSym_sym fs := SymSum.RSym_sum
  (SymSum.RSym_sum (SymSum.RSym_sum (SymEnv.RSym_func fs) RSym_ilfunc) RSym_bilfunc)
  RSym_Func'.

Definition Expr_expr_fs fs: ExprI.Expr _ (ExprCore.expr typ func) := @ExprD.Expr_expr typ func _ _ (RSym_sym fs).
Definition Expr_ok_fs fs: @ExprI.ExprOk typ RType_typ (ExprCore.expr typ func) (Expr_expr_fs fs) := ExprD.ExprOk_expr.

Check @exprD.

Definition reflect ft (tus tvs : env) e (ty : typ)
 := @exprD _ _ _ (Expr_expr_fs ft) tus tvs e ty.

Ltac do_reflect := 
cbv [reflect exprD exprD' Expr_expr_fs ExprD.Expr_expr
ExprDsimul.ExprDenote.exprD'
ExprDsimul.ExprDenote.OpenT
ExprDsimul.ExprDenote.Open_GetVAs
ExprDsimul.ExprDenote.Open_GetUAs
ExprDsimul.ExprDenote.Open_UseU
ExprDsimul.ExprDenote.Open_UseV
ExprDsimul.ExprDenote.func_simul
ExprDsimul.ExprDenote.funcAs
ExprDsimul.ExprDenote.Open_App
ExprDsimul.ExprDenote.Open_Inj
ExprDsimul.ExprDenote.Open_Abs
ExprDsimul.ExprDenote.Rcast_val
ExprDsimul.ExprDenote.Rcast
type_cast
nth_error_get_hlist_nth
FMapPositive.PositiveMap.find
ResType.OpenT
split_env
Monad.bind
Monad.ret
OptionMonad.Monad_option
elem_ctor
TypesI.typD
typD

symD

Relim

typeof_sym

RSym_sym
Rsym
SymSum.RSym_sum
SymEnv.RSym_func
SymEnv.func_typeof_sym
SymEnv.funcD
typeof_func_opt
SymEnv.ftype
RSym_bilfunc
RSym_Func'
RSym_ilfunc

BILogicFunc.RSym_bilfunc
BILogicFunc.typeof_bilfunc
BILogicFunc.funcD
bilops
ilops

ILogicFunc.fEntails
ILogicFunc.ILogicFuncExpr
ILogicFunc.ILogicFuncSumR
ILogicFunc.ILogicFuncSumL
ILogicFunc.BaseFuncInst
ILogic.ILogicOps_Prop
ILogicOps_mpred

BILogicFunc.mkEmp
BILogicFunc.fEmp
BILogicFunc.BILogicFuncSumL
BILogicFunc.BILogicFuncSumR
BILogicFunc.BaseFuncInst
BILogic.empSP
BILogic.sepSP
BILogic.wandSP

ModularFunc.ILogicFunc.RSym_ilfunc
ModularFunc.ILogicFunc.typeof_func
ModularFunc.ILogicFunc.funcD

typ2_match
typ2_cast
typ2
Typ2_tyArr
typ0_cast
typ0_match
typ0
Typ0_tyProp

HList.hlist_hd
HList.hlist_tl

typeof_func
typeof_const
typeof_z_op 
typeof_int_op 
typeof_value 
typeof_eval 
typeof_other 
typeof_sep 
typeof_lst 
typeof_triple

RType_typ

typ_eq_dec typ_rec typ_rect
False_ind False_rect True_ind True_rect
eq_ind eq_rec eq_rect
eq_sym sumbool_rec sumbool_rect
 eq_rec_r
f_equal

eqb_ident eqb_type 

funcD
tripleD

find
constD 
z_opD 
int_opD 
valueD 
evalD 
otherD 
sepD 
lstD ]. 

Goal forall sh contents p,
`(lseg LS sh (map Vint contents) p nullval) |--
`(lseg LS sh (map Vint contents) p nullval)
(*emp |-- emp*).
intros.
reify_vst (contents).
(*replace_lift. go_lower0.
reify_expr_tac.*)
assert (exists n, Some n = reflect tbl nil nil e (tylist tyint)).
eexists. unfold e. unfold tbl. 
do_reflect. 


SearchAbout find.
cbv.


cbv [eqb_ident].
unfold 
simpl. unfold RType_typ. 
simpl.
do_reflect. simpl. unfold BILogicFunc.mkEmp.
simpl. unfold reflect, exprD, exprD'. 
simpl. do_reflect. 
Goal forall (sh : share) (contents : list int) (p : val),
   PROP  ()
   LOCAL  (tc_environ Delta; `(eq p) (eval_id _t);
   `(eq (Vint (Int.repr 0))) (eval_id _s); `(eq p) (eval_id _p))
   SEP  (`(lseg LS sh (map Vint contents) p nullval))
   |-- PROP  ()
       LOCAL  (`(eq p) (eval_id _t);
       `(eq (Vint (Int.sub (sum_int contents) (sum_int contents))))
         (eval_id _s))
       SEP  (TT; `(lseg LS sh (map Vint contents) p nullval)).
intros.
replace_lift. go_lower0.
reify_expr_tac. Check reflect.
assert (exists v, v = reflect tbl nil nil e).
unfold e. eexists.
do_reflect. 

pose (c := cancel e).
unfold e in c.
compute in c.

Check exprD'.
reify_vst rho.
Eval compute in (reflect tbl0 nil nil e0 tyenviron).
assert (exists v, (reflect tbl0 nil nil e0 tyenviron = v)).
unfold e0.

simpl.
unfold typ_eq_dec.
cbv [typ_eq_dec typ_rec typ_rect].

Locate f1. simpl.

cbv [reflect exprD' Expr_expr_fs ExprD.Expr_expr
ExprDsimul.ExprDenote.exprD'
ExprDsimul.ExprDenote.OpenT
ExprDsimul.ExprDenote.Open_GetVAs
ExprDsimul.ExprDenote.Open_GetUAs
ExprDsimul.ExprDenote.Open_UseU
ExprDsimul.ExprDenote.Open_UseV
ExprDsimul.ExprDenote.func_simul
ExprDsimul.ExprDenote.funcAs
ExprDsimul.ExprDenote.Open_App
ExprDsimul.ExprDenote.Open_Inj
ExprDsimul.ExprDenote.Open_Abs
ExprDsimul.ExprDenote.Rcast_val
Monad.bind
Monad.ret
nth_error_get_hlist_nth
OptionMonad.Monad_option
TypesI.typD
type_cast
ResType.OpenT
typeof_sym
RSym_sym
typD
RType_typ
eq_sym
typ2_cast
typ2_match
Typ2_tyArr
HList.hlist_hd
HList.hlist_tl
typ_eq_dec typ_rec typ_rect
SymSum.RSym_sum
SymEnv.RSym_func
RSym_ilfunc
typeof_sym
SymEnv.func_typeof_sym
RSym_bilfunc
ModularFunc.ILogicFunc.RSym_ilfunc
ModularFunc.ILogicFunc.typeof_func
SymEnv.func_typeof_sym
SymEnv.ftype
BILogicFunc.RSym_bilfunc
RSym_Func'
BILogicFunc.typeof_bilfunc
BILogicFunc.mkEmp
FMapPositive.PositiveMap.find
typeof_func_opt].
Locate type_eq_dec.
unfold type_eq_dec.
Eval cbv in (reflect tbl0 nil nil e0 tyZ).
Check reflect.
Print RSym_env.
Print fs.
Locate fs.
Goal forall m n: nat, Some n = Some m -> False.
intros. congruence.

Check exprD'.
Eval vm_compute in reflect e.
assert (exists n, reflect e = n).
eexists. unfold reflect.
cbv in (reflect e).
simpl.
simpl. clear e.
unfold exprD'.
simpl.
Time Compute (cancel e).
reify_vst ( PROP  ()
   LOCAL  (tc_environ Delta; lift_eq_val p (eval_id _t);
   lift_eq_val (Vint (Int.repr 0)) (eval_id _s); lift_eq_val p (eval_id _p))
   SEP  (sp (lseg LS sh (map Vint contents) p nullval))
   |-- PROP  ()
       LOCAL  (lift_eq_val p (eval_id _t);
       lift_eq_val (Vint (Int.sub (sum_int contents) (sum_int contents)))
         (eval_id _s))
       SEP  (TT; sp (lseg LS sh (map Vint contents) p nullval))
).
reify_expr_tac.

Goal forall (sh : share) (contents : list val),
  writable_share sh ->
  forall (cts1 cts2 : list val) (w v : val),
    isptr v ->
   exists (a : Share.t) (b : val),
     PROP  (contents = (*rev*) cts1 ++ cts2)
     LOCAL  (tc_environ Delta2; `(eq w) (eval_id _w); 
     `(eq v) (eval_id _v))
     SEP  (`(lseg LS sh cts1 w nullval); `(lseg LS sh cts2 v nullval))
     |-- local (tc_expr Delta2 (Etempvar _v (tptr t_struct_list))) &&
         (`(field_at a t_struct_list (_tail::nil) b)
            (eval_expr (Etempvar _v (tptr t_struct_list))) * TT).
Proof.
intros. eexists. eexists. go_lower0.
reify_expr_tac.
Abort.

Goal forall n v, `(eq v) (eval_id _v) = n.
 intros.
Abort.
(* reify_expr_tac.*)


Existing Instance NullExtension.Espec.

Goal forall p contents sh,
semax Delta2
     (PROP  ()
      LOCAL  (`(eq p) (eval_id _p))  SEP  (`(lseg LS sh contents p nullval)))
     (Ssequence (Sset _w (Ecast (Econst_int (Int.repr 0) tint) (tptr tvoid)))
        Sskip) 
(normal_ret_assert (PROP  ()
      LOCAL  (`(eq (Vint (Int.repr 0))) (eval_id _w); 
      `(eq p) (eval_id _p))  SEP  (`(lseg LS sh contents p nullval)))).
intros.
replace_lift. 
reify_expr_tac. 
Abort.

Goal
  forall (sh : share) (contents : list int),
  PROP  ()
  LOCAL  (tc_environ Delta;
         `eq (eval_id _t) (eval_expr (Etempvar _p (tptr t_struct_list)));
         `eq (eval_id _s) (eval_expr (Econst_int (Int.repr 0) tint)))
  SEP  (`(lseg LS sh (map Vint contents)) (eval_id _p) `nullval)
          |-- EX  cts : list int,
  PROP  ()
  LOCAL 
        (`(eq (Vint (Int.sub (sum_int contents) (sum_int cts)))) (eval_id _s))
  SEP  (TT; `(lseg LS sh (map Vint cts)) (eval_id _t) `nullval).
Proof.
intros. 
replace_lift. 
Abort.


Goal
 forall (i : int) (cts : list int) (t0 y : val) (sh : share)
     (contents : list int),
   exists a, exists b,
   PROP  ()
   LOCAL  (tc_environ Delta; `(eq t0) (eval_id _t);
   `(eq (Vint (Int.sub (sum_int contents) (sum_int (i :: cts)))))
     (eval_id _s))
   SEP 
   (`(field_at sh t_struct_list _head (Vint i))
      (fun _ : lift_S (LiftEnviron mpred) => t0);
   `(field_at sh t_struct_list _tail y)
     (fun _ : lift_S (LiftEnviron mpred) => t0);
   `(lseg LS sh (map Vint cts)) `y `nullval; TT)
   |-- local (tc_expr Delta (Etempvar _t (tptr t_struct_list))) &&
       (`(field_at a t_struct_list _head b)
          (eval_expr (Etempvar _t (tptr t_struct_list))) * TT).
Proof.
intros. 
eexists. eexists.
go_lower0.