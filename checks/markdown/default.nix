{
  inputs,
  system,
  ...
}:
inputs.stc.lib.puritySeals.${system}.markdown {
  path = ./../..;
  args = "-d MD013,MD033";
}
