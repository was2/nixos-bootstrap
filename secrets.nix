let
  yubikey-primary = "age1yubikey1qw02nuf2tj56jgfnlr79gekywptl2ls2xklzu30kgjc34574atfzz6h68mg";
  yubikey-backup = "age1yubikey1qvtt0pdxcrf6uwslcuadnu6wtam5g8gxsem58q0kvtcqatgrax89kwk9k6h";



  yubikeys = [ yubikey-primary yubikey-backup ];
  all-keys = yubikeys;
in
{
  "secrets/wireguard/guest/key.age".publicKeys = all-keys;
  "secrets/wireguard/guest/endpoints/v4.age".publicKeys = all-keys;
  "secrets/wireguard/guest/endpoints/v6.age".publicKeys = all-keys;
}