Require Import MirrorCore.syms.SymEnv.
Require Import MirrorCore.Reify.Reify.
Require Import MirrorCore.Lambda.ExprCore.
Require Import types.
Require Import funcs.
Require Import MirrorCharge.ModularFunc.ILogicFunc.
Require Import MirrorCharge.ModularFunc.BILogicFunc.
Require Import floyd.local2ptree.
Require Import bool_funcs.

Local Notation "x @ y" := (@RApp x y) (only parsing, at level 30).
Local Notation "'!!' x" := (@RExact _ x) (only parsing, at level 25).
Local Notation "'?' n" := (@RGet n RIgnore) (only parsing, at level 25).
Local Notation "'?!' n" := (@RGet n RConst) (only parsing, at level 25).
Local Notation "'#'" := RIgnore (only parsing, at level 0).

Reify Declare Patterns patterns_vst_typ := typ.
Reify Declare Patterns patterns_vst := (ExprCore.expr typ func).
Reify Declare Patterns patterns_vst_hastype := (ExprCore.expr typ func).

Reify Declare Syntax reify_vst_typ :=
{ (@Patterns.CPatterns typ patterns_vst_typ) }.


Reify Declare Typed Table term_table : BinNums.positive => reify_vst_typ.

Let Ext x := @ExprCore.Inj typ func (inl (inl (inl x))).



Reify Declare Syntax reify_vst :=
  { (@Patterns.CFirst _  
      ((@Patterns.CVar _ (@ExprCore.Var typ func)) ::
       (@Patterns.CPatterns _ patterns_vst) ::
       (@Patterns.CApp _ (@ExprCore.App typ func)) ::
       (@Patterns.CAbs _ reify_vst_typ (@ExprCore.Abs typ func)) ::
       (@Patterns.CPatterns _ patterns_vst_hastype) ::
       (@Patterns.CTypedTable _ _ _ term_table Ext) :: nil))
  }.

Reify Pattern patterns_vst_typ += (!!Values.val) => tyval.
Reify Pattern patterns_vst_typ += (@RImpl (?0) (?1)) => 
       (fun (a b : Patterns.function reify_vst_typ) => tyArr a b). 
Reify Pattern patterns_vst_typ += (!!list_dt.listspec @ ?!0 @ ?!1 ) =>
       (fun (a : id Ctypes.type) (b : id AST.ident) => tylistspec a b).
Reify Pattern patterns_vst_typ += (!!AST.ident) => tyident.
Reify Pattern patterns_vst_typ += (!!expr.environ) => tyenviron.
Reify Pattern patterns_vst_typ += (!!shares.share) => tyshare.
Reify Pattern patterns_vst_typ += (!!shares.Share.t) => tyshare.
Reify Pattern patterns_vst_typ += (!!list @ ?0) =>
       (fun (a : Patterns.function reify_vst_typ) => tylist a).
Reify Pattern patterns_vst_typ += (!!expr.mpred) => tympred.
Reify Pattern patterns_vst_typ += (!!Prop) => typrop. 
Reify Pattern patterns_vst_typ += (!!juicy_extspec.OracleKind) => tyOracleKind.
Reify Pattern patterns_vst_typ += (!!bool) => tybool.
Reify Pattern patterns_vst_typ += (!!Integers.Int.int) => tyint.
Reify Pattern patterns_vst_typ += (!!Clight.expr) => tyc_expr.
Reify Pattern patterns_vst_typ += (!!Ctypes.type) => tyc_type.
Reify Pattern patterns_vst_typ += (!!expr.tycontext) => tytycontext.
Reify Pattern patterns_vst_typ += (!!BinNums.Z) => tyZ.
Reify Pattern patterns_vst_typ += (!!Datatypes.nat) => tynat.
Reify Pattern patterns_vst_typ += (!!BinNums.positive) => typositive.
Reify Pattern patterns_vst_typ += (!!expr.tc_assert) => tytc_assert.
Reify Pattern patterns_vst_typ += (!!Integers.comparison) => tycomparison.
Reify Pattern patterns_vst_typ += (!!Integers.int64) => tyint64.
Reify Pattern patterns_vst_typ += (!!Floats.float) => tyfloat.
Reify Pattern patterns_vst_typ += (!!Ctypes.typelist) => tytypelist.
Reify Pattern patterns_vst_typ += (!!Ctypes.fieldlist) => tyfieldlist.
Reify Pattern patterns_vst_typ += (!!Cop.binary_operation) => tybinary_operation.
Reify Pattern patterns_vst_typ += (!!Cop.unary_operation) => tyunary_operation.
Reify Pattern patterns_vst_typ += (!!BinNums.N ) => tyN.
Reify Pattern patterns_vst_typ += (!!option @ ?0) => 
    (fun (a : function reify_vst_typ) => tyoption a).
Reify Pattern patterns_vst_typ += (!!sum @ ?0 @ ?1) => 
    (fun (a b : function reify_vst_typ) => tysum a b).
Reify Pattern patterns_vst_typ += (!!prod @ ?0 @ ?1) => 
    (fun (a b : function reify_vst_typ) => typrod a b).
Reify Pattern patterns_vst_typ += (!!unit) => tyunit.
Reify Pattern patterns_vst_typ += (!!Clight.statement) => tystatement.
Reify Pattern patterns_vst_typ += (!!seplog.ret_assert) => tyret_assert.
Reify Pattern patterns_vst_typ += (!!SeparationLogic.ret_assert) => tyret_assert.

Reify Pattern patterns_vst_typ += (!!(lift.lifted (expr.LiftEnviron Prop))) => 
(tyArr tyenviron typrop).
Reify Pattern patterns_vst_typ += (!!(lift.lifted (expr.LiftEnviron expr.mpred))) => 
(tyArr tyenviron tympred).

Reify Pattern patterns_vst_typ += (!!@list_dt.elemtype @ ?0 @ ?1 @ ?2) =>
(fun (a : id Ctypes.type) (b : id AST.ident) (c : id (list_dt.listspec a b)) => 
  reptyp_structlist (@list_dt.all_but_link b (@list_dt.list_fields a b c))).
Reify Pattern patterns_vst_typ += (!!expr.exitkind) => tyexitkind.

Reify Pattern patterns_vst_typ += (!!Maps.PTree.t @ ?0) => 
(fun (a : function reify_vst_typ) => (typtree a)).


(*Zop*)

Reify Pattern patterns_vst += (!!BinInt.Z.lt) => (@Inj typ func (inr (Zop fZ_lt))).
Reify Pattern patterns_vst += (!!BinInt.Z.le) => (@Inj typ func (inr (Zop fZ_le))).
Reify Pattern patterns_vst += (!!BinInt.Z.gt) => (@Inj typ func (inr (Zop fZ_gt))).
Reify Pattern patterns_vst += (!!BinInt.Z.ge) => (@Inj typ func (inr (Zop fZ_ge))).
Reify Pattern patterns_vst += (!!BinInt.Z.add) => (@Inj typ func (inr (Zop fZ_add))).
Reify Pattern patterns_vst += (!!BinInt.Z.sub) => (@Inj typ func (inr (Zop fZ_sub))).
Reify Pattern patterns_vst += (!!BinInt.Z.mul) => (@Inj typ func (inr (Zop fZ_mul))).
Reify Pattern patterns_vst += (!!BinInt.Z.div) => (@Inj typ func (inr (Zop fZ_div))).
Reify Pattern patterns_vst += (!!Zdiv.Zmod) => (@Inj typ func (inr (Zop fZ_mod))).
Reify Pattern patterns_vst += (!!BinInt.Z.max) => (@Inj typ func (inr (Zop fZ_max))).
Reify Pattern patterns_vst += (!!BinInt.Z.opp) => (@Inj typ func (inr (Zop fZ_opp))).

Reify Pattern patterns_vst += (!!Integers.Int.add) => (@Inj typ func (inr (Intop fint_add))).
Reify Pattern patterns_vst += (!!Integers.Int.lt) => (@Inj typ func (inr (Intop fint_lt))).
Reify Pattern patterns_vst += (!!Integers.Int.ltu) => (@Inj typ func (inr (Intop fint_ltu))).
Reify Pattern patterns_vst += (!!Integers.Int.mul) => (@Inj typ func (inr (Intop fint_mul))).
Reify Pattern patterns_vst += (!!Integers.Int.neg) => (@Inj typ func (inr (Intop fint_neg))).
Reify Pattern patterns_vst += (!!Integers.Int.sub) => (@Inj typ func (inr (Intop fint_sub))).
Reify Pattern patterns_vst += (!!Integers.Int.cmp) => (@Inj typ func (inr (Intop fint_cmp))).
Reify Pattern patterns_vst += (!!Integers.Int.cmpu) => (@Inj typ func (inr (Intop fint_cmpu))).
Reify Pattern patterns_vst += (!!Integers.Int.repr) => (@Inj typ func (inr (Intop fint_repr))).
Reify Pattern patterns_vst += (!!Integers.Int.signed) => (@Inj typ func (inr (Intop fint_signed))).
Reify Pattern patterns_vst += (!!Integers.Int.unsigned) => (@Inj typ func (inr (Intop fint_unsigned))).
Reify Pattern patterns_vst += (!!Integers.Int.max_unsigned) => (@Inj typ func (inr (Intop fint_max_unsigned))).
Reify Pattern patterns_vst += (!!Integers.Int.repr) => (@Inj typ func (inr (Intop fint64_repr))).

Reify Pattern patterns_vst += (!!Values.Vint) => (@Inj typ func (inr (Value fVint))).
Reify Pattern patterns_vst += (!!Values.Vfloat) => (@Inj typ func (inr (Value fVfloat))).
Reify Pattern patterns_vst += (!!Values.Vlong) => (@Inj typ func (inr (Value fVlong))).
Reify Pattern patterns_vst += (!!Values.Vptr) => (@Inj typ func (inr (Value fVptr))).
Reify Pattern patterns_vst += (!!Values.Vundef) => (@Inj typ func (inr (Value fVundef))).
Reify Pattern patterns_vst += (!!expr.eval_cast @ ?0 @ ?1 ) => 
   (fun (a b: id Ctypes.type) => (@Inj typ func (inr (Eval_f (feval_cast a b))))).
Reify Pattern patterns_vst += (!!expr.deref_noload @ ?0 @ ?1) => (fun (a : id Ctypes.type) => (@Inj typ func (inr (Eval_f (fderef_noload a))))).
Reify Pattern patterns_vst += (!!expr.eval_field @ ?0 @ ?1) => (fun (a : id Ctypes.type) (b: id AST.ident) => (@Inj typ func (inr (Eval_f (feval_field a b))))).
Reify Pattern patterns_vst += (!!expr.eval_binop @ ?0 @ ?1 @ ?2) => 
(fun (a : id Cop.binary_operation) (b c : id Ctypes.type) => ((@Inj typ func (inr (Eval_f (feval_binop a b c)))))).
Reify Pattern patterns_vst += (!!expr.eval_unop @ ?0 @ ?1) => (fun (a : id Cop.unary_operation) (b : id Ctypes.type) =>  (@Inj typ func (inr (Eval_f (feval_unop a b))))).
Reify Pattern patterns_vst += (!!expr.eval_id @ ?0) => (fun (a : id AST.ident) => (@Inj typ func (inr (Eval_f (feval_id a))))).



Reify Pattern patterns_vst += (!!Zpower.two_power_nat) =>  (@Inj typ func (inr (Other ftwo_power_nat))).
Reify Pattern patterns_vst += (!!expr.force_ptr) =>  (@Inj typ func (inr (Other fforce_ptr))). 
Reify Pattern patterns_vst += (!!and) =>  (@Inj typ func (inr (Other fand))).
Reify Pattern patterns_vst += (!!Coqlib.align) =>  (@Inj typ func (inr (Other falign))).
Reify Pattern patterns_vst += (!!seplog.typed_true) => (@Inj typ func (inr (Other ftyped_true))).
Reify Pattern patterns_vst += 
      (!!@eq @ ?0) => (fun (a : function reify_vst_typ) 
                       => @Inj typ func (inr (Other (feq a)))).

Reify Pattern patterns_vst += (!!Clight.typeof) => (@Inj typ func (inr (Other ftypeof))).
Reify Pattern patterns_vst += (!!@Some @ ?0) => (fun (a : function reify_vst_typ) => 
     @Inj typ func (inr (Other (fsome a)))).
Reify Pattern patterns_vst += (!!@None @ ?0) => (fun (a : function reify_vst_typ) => 
     @Inj typ func (inr (Other (fnone a)))).

Reify Pattern patterns_vst += 
      (!!seplog.derives) => (fEntails (func := expr typ func) tympred).
Reify Pattern patterns_vst += 
      (!!seplog.sepcon) => (fStar (func := expr typ func) tympred).
Reify Pattern patterns_vst += 
      (!!seplog.emp) => (mkEmp (func := func) tympred).
Reify Pattern patterns_vst +=
      (!!@list_dt.lseg @ ?0 @ ?1 @ ?2) => 
         (fun  (a : id Ctypes.type) (b : id AST.ident) 
               (c : id (list_dt.listspec a b)) =>
              (@Inj typ func (inr (Sep (flseg a b c))))).
Reify Pattern patterns_vst += (!!seplog.TT) => (mkTrue (func := func) tympred).
Reify Pattern patterns_vst += (!!seplog.FF) => (mkFalse (func := func) tympred).
Reify Pattern patterns_vst += (!!seplog.andp) => (fAnd (func := expr typ func) tympred).
Reify Pattern patterns_vst += (!!seplog.orp) => (fOr (func := expr typ func) tympred).
Reify Pattern patterns_vst += (!!SeparationLogic.local) => (@Inj typ func (inr (Sep flocal))).
Reify Pattern patterns_vst += (!!seplog.prop) => (@Inj typ func (inr (Sep fprop))).

(*Reify Pattern patterns_vst += (!!client_lemmas.PROPx) => (@Inj typ func (inr (Smx fPROPx))).
Reify Pattern patterns_vst += (!!client_lemmas.LOCALx) => (@Inj typ func (inr (Smx fLOCALx))).
Reify Pattern patterns_vst += (!!client_lemmas.SEPx) => (@Inj typ func (inr (Smx fSEPx))).*)
Reify Pattern patterns_vst += (!!locallistD) => (@Inj typ func (inr (Smx flocallistD))).
Reify Pattern patterns_vst += (!!denote_tc_assert_b_norho) => (@Inj typ func (inr (Smx fdenote_tc_assert_b_norho))).
Reify Pattern patterns_vst += (!!tc_expr_b_norho) => (@Inj typ func (inr (Smx ftc_expr_b_norho))).
Reify Pattern patterns_vst += (!!tc_temp_id_b_norho) => (@Inj typ func (inr (Smx ftc_temp_id_b_norho))).
Reify Pattern patterns_vst += (!!msubst_eval_expr_norho) => (@Inj typ func (inr (Smx fmsubst_eval_expr_norho))).
Reify Pattern patterns_vst += (!!msubst_eval_lvalue_norho) => (@Inj typ func (inr (Smx fmsubst_eval_lvalue_norho))).

Reify Pattern patterns_vst += (!!SeparationLogic.normal_ret_assert) => (@Inj typ func (inr (Smx fnormal_ret_assert))).
Reify Pattern patterns_vst += (!!seplog.normal_ret_assert) => (@Inj typ func (inr (Smx fnormal_ret_assert))).


Reify Pattern patterns_vst += (!!@SeparationLogicSoundness.SoundSeparationLogic.CSL.semax) => (@Inj typ func (inr (Smx fsemax))).

Reify Pattern patterns_vst += (!!semax.semax) => (@Inj typ func (inr (Smx fsemax))).


Reify Pattern patterns_vst += (!!(@seplog.exp expr.mpred SeparationLogic.Nveric) @ ?0) => 
     (fun (a : function reify_vst_typ) => (fExists (func := expr typ func) a tympred)).

Reify Pattern patterns_vst += (!!(@seplog.allp expr.mpred SeparationLogic.Nveric) @ ?0) => 
     (fun (a : function reify_vst_typ) => (fForall (func := expr typ func) a tympred)).



Reify Pattern patterns_vst +=
      (!!@data_at_lemmas.data_at @ ?0) => 
         (fun  (a : id Ctypes.type)  =>
              (@Inj typ func (inr (Sep (fdata_at a ))))).

Reify Pattern patterns_vst +=
      (!!@field_at.field_at @ ?0 @ ?1) => 
         (fun  (a : id Ctypes.type) (b : id (list AST.ident)) =>
              (@Inj typ func (inr (Sep (ffield_at a b))))).

Reify Pattern patterns_vst += 
      (!!@map @ ?0 @ ?1) => (fun (a b: function reify_vst_typ) => 
                          (@Inj typ func (inr (Lst (fmap a b))))).


Reify Pattern patterns_vst +=
      (!!@nil @ ?0) => (fun (a : function reify_vst_typ) => 
        (@Inj typ func (inr (Lst (fnil a))))).


Reify Pattern patterns_vst +=
      (!!@fold_right @ ?0 @ ?1) => (fun (a b: function reify_vst_typ) =>
        (@Inj typ func (inr (Lst (ffold_right a b))))).

Reify Pattern patterns_vst +=
      (!!@fold_left @ ?0 @ ?1) => (fun (a b: function reify_vst_typ) =>
        (@Inj typ func (inr (Lst (ffold_left a b))))).

Reify Pattern patterns_vst +=
      (!!@cons @ ?0) => (fun (a : function reify_vst_typ) => 
        (@Inj typ func (inr (Lst (fcons a))))).

Reify Pattern patterns_vst += 
      (!!@pair @ ?0 @ ?1) => (fun (a b : function reify_vst_typ) =>
        (@Inj typ func (inr (Lst (fpair a b))))).

Reify Pattern patterns_vst +=
      (!!@app @ ?0) => (fun (a : function reify_vst_typ) => 
        (@Inj typ func (inr (Lst (fappend a))))).


Reify Pattern patterns_vst += 
      (RHasType AST.ident (?0)) => (fun (a : id AST.ident) 
                                       => (@Inj typ func (inr (Const (fPos a))))).

Reify Pattern patterns_vst_hastype += 
      (RHasType bool (?0)) => (fun (a : id bool) 
                                       => (@Inj typ func (inr (Const (fbool a))))).

Reify Pattern patterns_vst_hastype += 
      (RHasType Ctypes.type (?0)) => (fun (a : id Ctypes.type) 
                                       => (@Inj typ func (inr (Const (fCtype a))))).

Reify Pattern patterns_vst += 
      (RHasType expr.environ (?0)) => (fun (a : id expr.environ) 
                                       => (@Inj typ func (inr (Smx (fenviron a))))).

Reify Pattern patterns_vst += 
      (RHasType Clight.statement (?0)) => (fun (a : id Clight.statement) 
                                       => (@Inj typ func (inr (Smx (fstatement a))))).

Reify Pattern patterns_vst += 
      (RHasType Clight.expr (?0)) => (fun (a : id Clight.expr) 
                                       => (@Inj typ func (inr (Const (fCexpr a))))).


Reify Pattern patterns_vst +=
      (!!expr.update_tycon) => (@Inj typ func (inr (Smx (fupdate_tycon)))).


Reify Pattern patterns_vst_hastype += 
      (RHasType expr.tycontext (?0)) => (fun (a : id expr.tycontext) 
                                       => (@Inj typ func (inr (Smx (ftycontext a))))).



Reify Pattern patterns_vst_hastype += 
      (RHasType (Maps.PTree.tree (Ctypes.type * bool) * Maps.PTree.t Ctypes.type * Ctypes.type *
       Maps.PTree.tree expr.global_spec) (?0)) => (fun (a : id expr.tycontext) 
                                       => (@Inj typ func (inr (Smx (ftycontext a))))).

Reify Pattern patterns_vst_hastype += 
      (RHasType (Maps.PTree.tree (Ctypes.type * bool) * Maps.PTree.t Ctypes.type * Ctypes.type *
       Maps.PTree.tree expr.global_spec) (?0)) => (fun (a : id expr.tycontext) 
                                       => (@Inj typ func (inr (Smx (ftycontext a))))).

Reify Pattern patterns_vst += 
      (RHasType (Maps.PTree.t Values.val) (?0)) => (fun (a : id (Maps.PTree.t Values.val)) 
                                       => (@Inj typ func (inr (Smx (fvaltree a))))).


Reify Pattern patterns_vst += (RPi (?0) (?1)) => (fun (x : function reify_vst_typ) (y : function reify_vst) => 
  ExprCore.App (fForall (func := expr typ func) x typrop)
               (Abs x y)).

Reify Pattern patterns_vst += (!!localD @ (?0) @ (?1)) => 
(fun (a : id (Maps.PTree.t Values.val)) (b : id (Maps.PTree.t (Ctypes.type * Values.val)))
=> (@Inj typ func (inr (Smx (flocalD a b))))).

(*
Reify Pattern patterns_vst += (!!LocalD @ (?0) @ (?1) @ (?2)) => 
(fun (a : id (Maps.PTree.t Values.val)) (b : id (Maps.PTree.t (Ctypes.type * Values.val))) (c :id (list (expr.environ -> Prop)))
=> (@Inj typ func (inr (Smx (flocalD a b c))))).*)

Reify Pattern patterns_vst += (!!assertD) => (@Inj typ func (inr (Smx (fassertD)))).


(*Impl*)

Reify Pattern patterns_vst += (@RImpl (?0) (?1)) => 
       (fun (a b : Patterns.function reify_vst) => ((App (App (fImpl (func := expr typ func) typrop) a) b))). 



Ltac reify_typ trm :=
  let k e :=
      pose e
  in
  reify_expr reify_vst_typ k [ True ] [ trm ].


(*Ltac reify_vst trm:=
(*match goal with
[ |- ?trm ] => *)
  let k e :=
      pose e
  in
  reify_expr reify_vst k [ True ] [ trm ]
(*end*).*)

Let elem_ctor : forall x : typ, typD x -> @SymEnv.function _ _ :=
  @SymEnv.F _ _.

Ltac reify_vst e :=
  let k fs e :=
      pose e in
  reify_expr reify_vst k
             [ (fun (y : @mk_dvar_map _ _ _  _ term_table elem_ctor) => True) ]
             [ e ].

Ltac do_reify e :=
  let k fs e :=
     (apply e) in
  reify_expr reify_vst k
             [ (fun (y : @mk_dvar_map _ _ _ _ term_table elem_ctor) => True) ]
             [ e ].


Goal forall (Delta: expr.tycontext), False.
intros.
reify_vst (expr.update_tycon Delta Clight.Sskip).
Abort.