{ config, lib, pkgs, ... }:
{
    environment = {
        systemPackages = (with pkgs; [

        ]) ++ (with pkgs; [

        ]);
    };
}
