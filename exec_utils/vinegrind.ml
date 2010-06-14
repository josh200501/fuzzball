(*
 Owned and copyright BitBlaze, 2009-2010. All rights reserved.
 Do not copy, disclose, or distribute without explicit written
 permission.
*)

module FMM = Fragment_machine.FragmentMachineFunctor
  (Concrete_domain.ConcreteDomain)
module FMTM = Fragment_machine.FragmentMachineFunctor
  (Tagged_domain.TaggedDomainFunctor(Concrete_domain.ConcreteDomain))

let main argv = 
  Exec_set_options.set_defaults_for_concrete ();
  Options_linux.set_linux_defaults_for_concrete ();
  Arg.parse
    (Arg.align (Exec_set_options.cmdline_opts
		@ Options_linux.linux_cmdline_opts))
    (fun arg -> Exec_set_options.set_program_name arg)
    "vinegrind [options]* program\n";
  let fm = if !Exec_options.opt_use_tags then
    ((new FMTM.frag_machine) :> Fragment_machine.fragment_machine)
  else
    ((new FMM.frag_machine) :> Fragment_machine.fragment_machine)
  in
  let dl = Asmir.decls_for_arch Asmir.arch_i386 in
  let asmir_gamma = Asmir.gamma_create 
    (List.find (fun (i, s, t) -> s = "mem") dl) dl
  in
    fm#init_prog (dl, []);
    Exec_set_options.apply_cmdline_opts_early fm dl;
    Options_linux.apply_linux_cmdline_opts fm;
    Exec_set_options.apply_cmdline_opts_late fm;
    let (start_addr, fuzz_start) = Exec_set_options.decide_start_addrs () in
      Exec_fuzzloop.fuzz start_addr fuzz_start
	!Exec_options.opt_fuzz_end_addrs fm asmir_gamma (fun () -> ())
;;

main Sys.argv;;
