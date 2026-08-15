{ pkgs, ... }:

{
  systemd.tmpfiles.rules = [
    "L+ /usr/share/OVMF/OVMF_CODE.fd - - - - ${pkgs.OVMF.firmware}"
    "L+ /usr/share/OVMF/OVMF_CODE_4M.fd - - - - ${pkgs.OVMF.firmware}"
    "L+ /usr/libexec/virtiofsd - - - - ${pkgs.virtiofsd}/bin/virtiofsd"
    "L+ /usr/bin/virtiofsd - - - - ${pkgs.virtiofsd}/bin/virtiofsd"
  ];

  boot.kernelModules = [ "vhost_vsock" ];

  users.users.brunostjohn.extraGroups = [ "kvm" ];
}
