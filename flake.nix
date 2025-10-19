{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = inputs@{ self, flake-parts, ... }:
    flake-parts.lib.mkFlake
      { inherit inputs; }
      ({ lib, ... }: {
        imports = [
          inputs.git-hooks-nix.flakeModule
        ];
        systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
        perSystem = { config, self', inputs', pkgs, ... }:
          let
            inherit (lib) getExe';
            inherit (builtins) toString;

            packageOverrides = pkgs.callPackage ./python-packages.nix { };
            python = pkgs.python3.override { inherit packageOverrides; };
            pythonWithPackages = python.withPackages (ps: with ps; [
              certifi
              charset-normalizer
              idna
              readchar
              requests
              urllib3
            ]);
          in
          {
            pre-commit.settings.hooks.nixpkgs-fmt.enable = true;

            devShells.default = pkgs.mkShell {
              shellHook = ''
                ${config.pre-commit.shellHook}
              '';

              packages = config.pre-commit.settings.enabledPackages ++ [
                pythonWithPackages
              ];
            };

            # TODO: use buildPythonPackage somehow?
            packages.default = pkgs.writeShellScriptBin "gopro-plus" ''
              
              ${getExe' pythonWithPackages "python"} "${toString ./.}/main.py" $@
            '';
          };
      });
}
