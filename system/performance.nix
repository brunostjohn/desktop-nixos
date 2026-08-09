{ ... }:

{
  boot.kernel.sysctl = {
    "vm.swappiness" = 150;
    "vm.page-cluster" = 0;
    "vm.vfs_cache_pressure" = 50;
    "kernel.sysrq" = 176;
  };
}
