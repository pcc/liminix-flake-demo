{
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.liminix = {
    url = "github:pcc/liminix/flake-demo";
    flake = false;
  };
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    {
      self,
      flake-utils,
      liminix,
      nixpkgs,
    }:
    let
      qemu = {
        device = import "${liminix}/devices/qemu-aarch64";
        wan = config: config.hardware.networkInterfaces.wan;
        lan =
          config: with config.hardware.networkInterfaces; [
            wlan_24
            lan
          ];
        wlan24 = config: config.hardware.networkInterfaces.wlan_24;
      };
      openwrt-one = {
        device = import "${liminix}/devices/openwrt-one";
        wan = config: config.hardware.networkInterfaces.eth1;
        lan =
          config: with config.hardware.networkInterfaces; [
            wlan0
            wlan1
            eth0
          ];
        wlan24 = config: config.hardware.networkInterfaces.wlan0;
        wlan5 = config: config.hardware.networkInterfaces.wlan1;
      };
      turris-omnia = {
        device = import "${liminix}/devices/turris-omnia";
        wan = config: config.hardware.networkInterfaces.wan;
        lan =
          config: with config.hardware.networkInterfaces; [
            wlan
            wlan5
            lan
          ];
        wlan24 = config: config.hardware.networkInterfaces.wlan;
        wlan5 = config: config.hardware.networkInterfaces.wlan5;
      };
    in
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgsWithAttrs =
          attrs:
          (import "${liminix}/default.nix" {
            liminix-config = import ./configuration.nix attrs;
            device = attrs.device;
            nixpkgs = nixpkgs;
            system = system;
          }).outputs;
        pkgsForDevice =
          attrs:
          (pkgsWithAttrs attrs)
          // {
            tftpboot =
              (pkgsWithAttrs (
                {
                  fs = "squashfs";
                  debuggable = true;
                }
                // attrs
              )).tftpboot;
          };
      in
      {
        packages = {
          qemu = pkgsForDevice qemu;
          openwrt-one = pkgsForDevice openwrt-one;
          turris-omnia = pkgsForDevice turris-omnia;
        };
      }
    );
}
