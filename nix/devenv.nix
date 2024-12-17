{
  perSystem =
    { pkgs, ... }:
    {
      treefmt = {
        projectRootFile = "flake.nix";
        enableDefaultExcludes = true;
        programs = {
          actionlint.enable = true;
          deadnix.enable = true;
          nixfmt.enable = true;
          prettier.enable = true;
          shfmt.enable = true;
          statix.enable = true;
        };
        settings.global.excludes = [
          "LICENSE"
        ];
      };
      devenv.shells.default = {
        containers = pkgs.lib.mkForce { };
        languages = {
          javascript = {
            enable = true;
            npm.enable = true;
          };
          nix.enable = true;
        };
        cachix = {
          enable = true;
          push = "shikanime";
        };
        pre-commit.hooks = {
          shellcheck.enable = true;
        };
        packages = [
          pkgs.gh
        ];
      };
    };
}
