---
title: "Initial testing"

date: 2025-09-16T20:18:14

draft: false

categories:
  - posts
  - HUGO

tags:
  - markdown
  - HUGO
  - WebServer
---

Over the last couple of years i have been learning Linux, Nix, "Dev Ops" and much more, and thinking about where the world is heading i think that sharing my voice in this big chaos of a world could bring some good into it.
This page will be do document how i have set up HUGO in nix, how i am using nix to build my website and post it to github pages, and how it all fits together.

## Setting up flake.nix

Setup of ones flakes always seems like a bit of a gamble, i am still new to this, so much of this is with the help of the AI gods. (May god have mercy on my soul)

### Nix inputs

Inputs in nix is as the name suggest where packages and data comes from, in my flake.nix i have packages coming in from nixpkgs, (Nix's large repo containing most packages in nix) flake-utils, a repo containing a tool to work with flakes, and some git repos that provides themes for HUGO.

Inputs are defined under Inputs (Duuh!...) where we tell nix where to find the packages, and in my case if some of them are flakes or just normal git repos.

```Nix
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
```

In contrast to normal HUGO themes where you would implement themes as a sub-module, in nix we can get nix to download and keep a git repo in line with reality. We could from the inputs peg the git repo to a tag, sha, a branch, or even a sub-directory of a repo, but by not specifying anything we are pulling from the "main" branch and the newest version. For more information please see: [NixOs & Flakes Book: Flake Inputs](https://nixos-and-flakes.thiscute.world/other-usage-of-flakes/inputs)

An advantage about having nix handle the repos is that we will be be able to go back in time and get the blowfish repo from when this version of the blog is made, as the blowfish repo sha is saved in the flake.lock file, and when we build the website from this version of our repo, the version of the blowfish repo that is saved in flake.lock will be the one that is downloaded.

### Nix outputs

After inputs we have outputs, outputs is what is actually going to be done when different "nix command's" are run. To start out we define what will be available from input, this is a bit more complex than what it originally seems.

#### Self

Self is a special input that all flakes has that provides a way to reference the flake itself, this is used in cases where the source code of ones own repo is used. It is always available to be used in the outputs sections, and can be referenced without the fear of circular implementations.

#### Input definitions

We can also reference the repos we have defined in the inputs section, in this example we reference nixpkgs and flake-utils, this ensures that we can use these references further down in the outputs.

#### dots and @inputs

While i cannot find documentation on this, from experimentations it seems to work like this:

- @inputs ensures that inputs can be reached through "inputs.nixpkgs", but standalone only inputs defined in the outputs section is available.
- 3 dots (...) ensures that when using inputs.whatever you can reach input packages not used in outputs.

Only using one or the other will not allow you to reference inputs that is not reference in the outputs using inputs.whatever. To the best of my knowledge this is due to support of legacy implementations.

```Nix {lineNos=true}
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
```

### Flake-utils and what it dots

By default you would need to specify a build for each kind of system that your application is build for. As a example:

```Nix {lineNos=true}
  outputs = {
    packages.x86_64-linux.default = /* something */;
    packages.aarch64-linux.default = /* something */;
    packages.x86_64-darwin.default = /* something */;
    packages.aarch64-darwin.default = /* something */;

    devShells.x86_64-linux.default = /* something */;
    devShells.aarch64-linux.default = /* something */;
    # ... repeat for every system
  };
```

Flake-utils removes some of this boilerplate code, making it so you do not have to implement the same logic over and over again, one of the disadvantages of using this is that if you need something special for a specific arch you would have to implement this logic in your code instead of build packages.

### Variables

Variables in nix is always defined in let ... in blocks, this is a design choice to ensure immutability, easier lazy evaluation, and to ensure that variables will always be the same during evaluation.
Once a variable is set it cannot be changed again.

#### pkgs

pkgs is a variable created to easily reference packages in nixpkgs, legacyPackages is a attribute set that contains all packages in nixpkgs, its a implementation that is created in flakes and has a odd name as packages is a existing name that cannot be used elsewhere. ${system} is a reference to the flake-utils variable for the current system you are building for.

#### themeSource

This is a variable that contains a attribute from inputs, builtins.getAttr gets a attribute from inputs based on the content of the variable selectedTheme.

### Output content

```Nix {linsNos=true}
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
...
```
