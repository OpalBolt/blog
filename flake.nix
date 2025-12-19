{
  description = "Simple Hugo flake for creating blog";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    paper-mod = {
      url = "github:adityatelange/hugo-PaperMod";
      flake = false;
    };
    blowfish = {
      url = "github:nunocoracao/blowfish";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }@inputs:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        selectedTheme = "blowfish";
        themeSource = builtins.getAttr selectedTheme inputs;
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "skumnet.dk";
          version = "0.1.0";
          src = self;
          buildInputs = [ pkgs.hugo ];

          configurePhase = ''
            mkdir -p themes
            ln -snf ${themeSource} themes/default
          '';

          buildPhase = ''
            ${pkgs.hugo}/bin/hugo --gc --minify
          '';

          installPhase = ''
            mkdir -p $out
            cp -r public/* $out/
          '';
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            #self.packages.${system}.default <-- we do not want to build the project every time we enter the shell
            hugo
            go-task
            nodePackages.prettier
            markdownlint-cli
            deadnix
            statix
            yamllint
            yq-go
            imagemagick_light
            libwebp
          ];
          shellHook = ''
            echo "In dev shell. Try: hugo server -D"
            mkdir -p themes
            ln -snf "${themeSource}" themes/default

          '';
        };
      }
    );
}
