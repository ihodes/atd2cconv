open Nonstd
open Printf

let say fmt = Printf.(ksprintf (eprintf "%s\n%!") fmt)
let failwithf fmt = Printf.(ksprintf failwith fmt)

let () =
  let inherit_variants = ref false in
  let input = ref None in
  let output = ref None in
  let options = Arg.(align [
      "-inline-inherit-variants",
      Bool (fun v -> inherit_variants := v),
      "<true|false> \n\tWrite inheriting variants inline (default: false)";
      "-i",
      String (fun s -> input := Some s),
      "<file> \n\tInput ATD file (default: stdin)";
      "-o",
      String (fun s -> output := Some s),
      "<file> \n\tOutput ML file (default: stdout)";
    ]) in
  let annons s = say "Dunno what to do with %S" s in
  let usage = sprintf "%s [OPTIONS] <input.atd> <output.ml>" Sys.argv.(0) in
  Arg.parse options annons usage;
  let (i, closi), (o, closo) =
    Option.value_map ~default:(stdin, fun _ -> ()) !input 
      ~f:(fun f -> open_in f, close_in),
    Option.value_map ~default:(stdout, fun _ -> ()) !output 
      ~f:(fun f -> open_out f, close_out) in
  let atd = 
    Atd_util.read_channel 
      ~inherit_fields:true
      ~inherit_variants:!inherit_variants i in
  let (full_module, original_types) = atd in
  let (head, body) = full_module in
  List.iter body ~f:(fun item ->
      match Atd2cconv.transform_module_item item with
      | `Ok doc ->
        SmartPrint.to_out_channel 78 2 o doc;
        output_string o "\n\n"
      | `Error (`Not_implemented msg) ->
        say "Error: %S not implemented" msg
    );
  closi i;
  closo o;
  ()



