Load loadpath.
Require Import msl.base 
               veric.sim veric.step_lemmas veric.base veric.expr
               veric.extensions veric.extspec veric.null_extension
               veric.juicy_mem veric.juicy_extspec veric.Address.

Set Implicit Arguments.

Inductive fmode: Type := RDONLY | WRONLY | RDWR.

Definition fwritable (mode: fmode) :=
  match mode with
  | RDONLY => false
  | WRONLY => true
  | RDWR => true
  end.

(* model of a simple "flat" filesystem *)

Inductive file: Type := mkfile: forall (size: nat) (contents: forall (ofs: nat), memval), file.

Definition fptr := nat.

(*typedef struct {
  int cur_dir; // i-node of the current working directory
  int n_inodes; // allocated i-nodes
  int n_open_files;
  uint8_t map_open_files[BITMAP_SIZE(N_INODES)];
  uint8_t map_inodes[BITMAP_SIZE(N_INODES)];
  uint8_t map_blocks[BITMAP_SIZE(N_BLOCKS)];
  uint32_t fd_map[MAX_OPEN_FILES]; // maps FDs to i-nodes
  uint32_t fptr_map[MAX_OPEN_FILES]; // maps FDs to file pointers
  file_mode_t fperm_map[MAX_OPEN_FILES]; // maps FDs to file permissions
  uint8_t block_cache[CACHE_N_BLOCKS][BLOCK_SIZE]; // data block cache
  uint32_t cache_map[CACHE_N_BLOCKS]; // maps cache block # to data block #
  uint32_t cache_last_access_map[CACHE_N_BLOCKS]; // maps cache block # to approximate time since last access
} fs_data;*)

Inductive fs_data: Type := mkfsdata: forall 
  (fdtable: forall (fd: int), option (fmode*fptr)) (*None = fd unused*)
  (fcache: forall (fd: int), option file) (*models in-memory storage*)
  (nfiles_open: int) (*number of files currently open*)
  (fnames: forall (fd: int), option int) (*map from file descriptors to file names*), 
  fs_data.

Inductive fs: Type := mkfs: forall 
  (fsdata: fs_data)
  (fstore: forall (name: int), option file), (*models on-disk storage*)
  fs.

Section selectors.
Variable (fs: fs).
Definition get_fsdata := match fs with mkfs fsdata _ => fsdata end.
Definition get_fstore := match fs with mkfs _ fstore => fstore end.

Definition get_fdtable := match get_fsdata with mkfsdata fdtable _ _ _ => fdtable end.
Definition get_fcache := match get_fsdata with mkfsdata _ fcache _ _ => fcache end.
Definition get_nfiles_open := match get_fsdata with mkfsdata _ _ nfiles_open _ => nfiles_open end.
Definition get_fnames := match get_fsdata with mkfsdata _ _ _ fnames => fnames end.

Variable (fd: int).
Definition get_file := get_fcache fd. 
Definition get_fmode := 
  match get_fdtable fd with 
  | None => None 
  | Some (md, cur) => Some md
  end.
Definition get_fptr := 
  match get_fdtable fd with 
  | None => None 
  | Some (md, cur) => Some cur
  end.

Variable (f: file).
Definition get_size := match f with mkfile sz _ => sz end.
Definition get_contents := match f with mkfile _ contents => contents end.

End selectors.

(*return the highest unallocated file descriptor, or None if none available*)
Section alloc_fd.
Variable (fs: fs).

Fixpoint find_unused_fd (n: nat) (fdtable: int -> option file) :=
  match n with 
  | O => None
  | S n' => match fdtable (Int.repr (Z_of_nat n)) with 
            | None => Some (Int.repr (Z_of_nat n))
            | Some _ => find_unused_fd n' fdtable
            end
  end.

Definition MAX_FILE_DESCRIPTORS := (*(nat_of_Z Int.modulus)*) 10%nat.

Definition alloc_fd := find_unused_fd MAX_FILE_DESCRIPTORS (get_fcache fs).

End alloc_fd.

Definition mount_fs (fstore: forall (name: int), option file) := 
  mkfs (mkfsdata (fun _:int => None) (fun _:int => None) Int.zero (fun _:int => None)) fstore.

Section FSExtension.
Variables 
  (Z cT D: Type) 
  (csem: CoreSemantics genv cT mem D)
  (client_sig: ext_sig mem fs)

  (after_at_external_excl: forall c ret c',
    after_external csem ret c = Some c' -> at_external csem c' = None)
  (at_external_handled: forall c ef args sig,
    at_external csem c = Some (ef, sig, args) -> IN ef client_sig = true)

  (init_world: Z).

Definition cores := fun _:nat => Some csem.

Local Open Scope nat_scope.

Inductive xT: Type := mkxT: forall (z: Z) (c: cT) (fs: fs), xT.

Section selectors.
Variable (s: xT).

Definition get_ext := match s with mkxT z _ _ => z end.
Definition get_core := match s with mkxT _ c _ => c end.
Definition get_fs := match s with mkxT _ _ fs => fs end.

End selectors.

Definition proj_core (s: xT) (i: nat) := if eq_nat_dec i 1 then Some (get_core s) else None.
Definition active := fun _: xT => 1.
Definition runnable := fun (ge: genv) (s: xT) => 
  match at_external csem (get_core s), safely_halted csem ge (get_core s) with 
  | None, None => Some 1
  | _, _ => None
  end.
Definition proj_zint := get_fs.
Definition proj_zext := get_ext.
Definition zmult := @prod Z fs. 

(*SYS_READ/WRITE_SIG: fd, buf, count*)
Notation SYS_READ_SIG := (mksignature (AST.Tint::AST.Tint::AST.Tint::nil) (Some AST.Tint)).
Notation SYS_WRITE_SIG := (mksignature (AST.Tint::AST.Tint::AST.Tint::nil) (Some AST.Tint)).
(*SYS_OPEN_SIG: name*)
Notation SYS_OPEN_SIG := (mksignature (AST.Tint::AST.Tint::nil) (Some AST.Tint)).

Notation SYS_READ := (EF_external 3%positive SYS_READ_SIG).
Notation SYS_WRITE :=  (EF_external 4%positive SYS_WRITE_SIG).
Notation SYS_OPEN := (EF_external 8%positive SYS_OPEN_SIG).

Definition int2fmode (i: int): option fmode := 
  if Int.eq i Int.zero then Some RDONLY 
  else if Int.eq i Int.one then Some WRONLY
       else if Int.eq i (Int.repr 3%Z) then Some RDWR
            else None.

Definition val2oint (v: val): option int :=
  match v with
  | Vundef => None
  | Vint i => Some i
  | Vfloat _ => None
  | Vptr _ _ => None
  end.

Definition val2oadr (v: val): option address :=
  match v with
  | Vundef => None
  | Vint i => None
  | Vfloat _ => None
  | Vptr b ofs => Some (b, Int.intval ofs)
  end.

Definition val2omode (mode: val): option fmode :=
  match val2oint mode with Some i => int2fmode i | None => None end.

Section read_write.
Variable (f: file) (fptr: nat).

Let contents := get_contents f.

Fixpoint read_file_aux (nbytes sz cur: nat): list memval :=
  match nbytes with 
  | O => nil
  | S nbytes' => if eq_nat_dec sz cur then nil 
                 else contents cur :: read_file_aux nbytes' sz (S cur)
  end.

Definition read_file (nbytes: nat): list memval := read_file_aux nbytes (get_size f) fptr.

Fixpoint write_file_aux (bytes: list memval) (sz cur: nat): (nat -> memval)*nat :=
  match bytes with 
  | nil => (contents, O)
  | byte::bytes' => 
    match write_file_aux bytes' sz (S cur) with (contents', nbytes) => 
        (fun ofs => if eq_nat_dec ofs cur then byte else contents' ofs, S nbytes)
    end
  end.

Definition write_file (bytes: list memval): file*nat :=
  match write_file_aux bytes (get_size f) fptr with (contents, nwritten) => 
    (mkfile (get_size f + (fptr + nwritten - get_size f)) (get_contents f), nwritten)
  end.

End read_write.

Section fs_read_write.
Variables (fsys: fs) (fd: int).

Definition fs_read (nbytes: nat): option (list memval) := 
  match get_file fsys fd, get_fptr fsys fd with
  | Some f, Some cur => Some (read_file f cur nbytes)
  | _, _ => None
  end.

Definition fs_write (bytes: list memval): option (nat(*nbytes written*)*fs) :=
  match get_file fsys fd, get_fptr fsys fd, get_fmode fsys fd with
  | Some file, Some cur, Some md => 
    if fwritable md then 
      match write_file file cur bytes with (new_file, nbytes_written) => 
        Some (nbytes_written, 
              mkfs (mkfsdata (fun i => if Int.eq fd i then Some (md, cur + nbytes_written)
                                       else get_fdtable fsys i)
                             (fun i => if Int.eq fd i then Some new_file
                                       else get_fcache fsys i)
                             (get_nfiles_open fsys)
                             (get_fnames fsys))
                   (get_fstore fsys))
       end
     else None
  | _, _, _ => None
  end.

End fs_read_write.

Definition new_file := mkfile O (fun _:nat => Undef).

Section fs_open.
Variable (fsys: fs) (unused_fd: int).

Definition fs_open_existing (fname: int) (f: file) (md: fmode): fs :=
  mkfs (mkfsdata (fun i => if Int.eq i unused_fd then Some (md, O) 
                           else get_fdtable fsys i)
                 (fun i => if Int.eq i unused_fd then Some f
                           else get_fcache fsys i)
                 (Int.add Int.one (get_nfiles_open fsys))
                 (fun i => if Int.eq i unused_fd then Some fname 
                           else get_fnames fsys i))
       (get_fstore fsys).

Definition fs_open_new (fname: int) (md: fmode): fs := 
  mkfs (mkfsdata (fun i => if Int.eq i unused_fd then Some (md, O) 
                           else get_fdtable fsys i)
                 (fun i => if Int.eq i unused_fd then Some new_file
                           else get_fcache fsys i)
                 (Int.add Int.one (get_nfiles_open fsys))
                 (fun i => if Int.eq i unused_fd then Some fname 
                           else get_fnames fsys i))
       (get_fstore fsys).

Definition fs_open (fname: int) (md: fmode): option fs :=
  match fwritable md, get_fstore fsys fname with
  | false, Some f => Some (fs_open_existing fname f md)
  | false, None => None
  | true, Some f => Some (fs_open_existing fname f md)
  | true, None => Some (fs_open_new fname md)
  end.

End fs_open.

Definition handled: list AST.external_function := SYS_READ::SYS_WRITE::SYS_OPEN::nil.

Definition is_open (fsys: fs) (fname: int) := exists fd, get_fnames fsys fd = Some fname.

Inductive os_step: genv -> xT -> mem -> xT -> mem -> Prop :=
| os_corestep: forall ge s m s' m',
  get_fs s=get_fs s' -> 
  get_ext s=get_ext s' -> 
  corestep csem ge (get_core s) m (get_core s') m' -> 
  os_step ge s m s' m'
| os_open: forall ge z s m c md0 fname0 md fname unused_fd fs',
  let fs := get_fs s in 
  at_external csem (get_core s) = Some (SYS_OPEN, SYS_OPEN_SIG, fname0::md0::nil) ->
  alloc_fd fs = Some unused_fd ->
  val2omode md0 = Some md -> 
  val2oint fname0 = Some fname -> 
  ~is_open fs fname -> 
  fs_open fs unused_fd fname md = Some fs' -> 
  after_external csem (Some (Vint unused_fd)) (get_core s) = Some c -> 
  os_step ge s m (mkxT z c fs') m
| os_read: forall ge z s m c fd0 fd buf adr nbytes0 nbytes bytes m',
  let fs := get_fs s in
  at_external csem (get_core s) = Some (SYS_READ, SYS_READ_SIG, fd0::buf::nbytes0::nil) ->
  val2oint fd0 = Some fd -> 
  val2oadr buf = Some adr -> 
  val2oint nbytes0 = Some nbytes -> 
  fs_read fs fd (nat_of_Z (Int.intval nbytes)) = Some bytes -> 
  Mem.storebytes m (fst adr) (snd adr) bytes = Some m' -> 
  after_external csem (Some (Vint (Int.repr (Zlength bytes)))) (get_core s) = Some c -> 
  os_step ge s m (mkxT z c fs) m'
| os_write: forall ge z s m c fd0 fd adr buf nbytes0 nbytes bytes fs' nbytes_written,
  let fs := get_fs s in
  at_external csem (get_core s) = Some (SYS_WRITE, SYS_WRITE_SIG, fd0::buf::nbytes0::nil) ->
  val2oint fd0 = Some fd -> 
  val2oadr buf = Some adr -> 
  val2oint nbytes0 = Some nbytes -> 
  Mem.loadbytes m (fst adr) (snd adr) (Int.intval nbytes) = Some bytes -> 
  fs_write fs fd bytes = Some (nbytes_written, fs') -> 
  after_external csem (Some (Vint (Int.repr (Z_of_nat nbytes_written)))) (get_core s) = Some c -> 
  os_step ge s m (mkxT z c fs') m.

Definition os_initial_mem := sim.initial_mem csem.

Definition os_make_initial_core (ge: genv) (v: val) (args: list val): option xT :=
  match make_initial_core csem ge v args with
  | Some c => Some (mkxT init_world c (mount_fs (fun _: int => None)))
  | None => None
  end.

Definition os_at_external (s: xT) :=
  match at_external csem (get_core s) with
  | Some (SYS_READ, SYS_READ_SIG, args) => None
  | Some (SYS_WRITE, SYS_WRITE_SIG, args) => None
  | Some (SYS_OPEN, SYS_OPEN_SIG, args) => None
  | Some (ef, sig, args) => Some (ef, sig, args)
  | None => None
  end.

Definition os_after_external (ov: option val) (s: xT): option xT :=
  match after_external csem ov (get_core s) with
  | Some c => Some (mkxT (get_ext s) c (get_fs s))
  | None => None
  end.

Definition os_safely_halted (ge: genv) (s: xT): option int :=
  safely_halted csem ge (get_core s).

Program Definition FSCoreSem := Build_CoreSemantics genv xT mem D
  os_initial_mem
  os_make_initial_core
  os_at_external
  os_after_external
  os_safely_halted
  os_step
  _ _ _.
Next Obligation.
case_eq (at_external csem (get_core q)).
2: unfold os_at_external; intros H1; rewrite H1; auto.
intros [[ef sig] args] H1.
inv H.
apply corestep_not_at_external in H3; congruence.
unfold os_at_external; rewrite H0; auto.
unfold os_at_external; rewrite H0; auto.
unfold os_at_external; rewrite H0; auto.
Qed.
Next Obligation.
inv H.
apply corestep_not_halted in H2.
unfold os_safely_halted; rewrite H2; auto.
edestruct (at_external_halted_excl csem); eauto. congruence.
edestruct (at_external_halted_excl csem); eauto. congruence.
edestruct (at_external_halted_excl csem); eauto. congruence.
Qed.
Next Obligation.
edestruct (at_external_halted_excl csem); eauto.
left; unfold os_at_external; rewrite H; auto.
Qed.

Definition JuicyFSCoreSem := juicy_core_sem FSCoreSem.

Definition isSome {A: Type} (o: option A) :=
  match o with Some _ => true | None => false end.

Definition Client_FSExtSpec :=
  Build_external_specification juicy_mem AST.external_function (Z*fs)
  (fun ef: AST.external_function => unit (*placeholder for now*))
  (fun (ef: AST.external_function) u typs args zfs jm => 
    match ef, zfs, args with
      SYS_OPEN, (z, fs), mode::nil => 
      nat_of_Z (Int.intval (get_nfiles_open fs)) < nat_of_Z Int.max_unsigned
    | SYS_READ, (z, fs), fd::buf::nbytes => False (*TODO*)
    | SYS_WRITE, (z, fs), fd::buf::nbytes => False (*TODO*)
    | _, _, _ => False
    end)
  (fun (ef: AST.external_function) u ty retval zfs jm => 
    match ef, zfs with
    | SYS_OPEN, (z, fs) => True (*TODO*)
    | _, (_, _) => True (*TODO*)
    end).

Program Definition Client_JuicyFSExtSpec := 
  Build_juicy_ext_spec (Z*fs) Client_FSExtSpec _ _.
Next Obligation. hnf; intros a a' H; destruct e; auto. Qed.
Next Obligation. hnf; intros a a' H; destruct e; auto. Qed.

End FSExtension.
