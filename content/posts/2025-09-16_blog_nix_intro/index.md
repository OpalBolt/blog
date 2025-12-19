---
title: "Intro to how this blog works (And nix, mostly nix)"

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

> Finding actual information about this is very hard.

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

Finding a exhaustive list of the kind of output objects there exist is hard, a list i could find is here: [nixos.wiki: Flakes](https://nixos.wiki/wiki/Flakes#Output_schema) while there are many kind of output objects to choose from we are going to be looking at the following: packages, apps, and devShells. Most output object takes a derivation as a argument

#### But what are derivations?

Derivations are instructions for building a package in Nix, it takes a list of argument and based on these arguments build the output that is required. The end product of a derivation would in most cases be software. While there are many options for creating defivations the one we are going to be using is stdenv.mkDerivation. stdenv is the standard environment for building packages, it comes with a small list of tools like coreutils, gnu c compiler and more, this ensures that you can use this as a good base for building your software. For more information see [Nixpkgs manual: stdenv](https://ryantm.github.io/nixpkgs/stdenv/stdenv/)

#### Building a package

Here we are defining a package called default, we are filling this package with a derivation using stdenv.mkDerivation. We need to define some options for mkDerivation in order for it to build our package, while mkDerivation has loads of different options the bare minimum to define is a name and a src. Below is

**src**
: src is the source for this derivation, this can be a repo hosted somewhere online, it can be a file downloaded from the internet, or as in our case it can be the project itself as specified using self.

**pname**
: pname is the same as name, but when using pname nix will automatically set name to `"${pname}-${version}"`

**buildInputs**
: buildInputs are the pa

Here we are defining a package called default, we are filling it with a derivation that is the output of the repo we are working within. In this case the source of this package "src" is "self". We provide a name, and version which is simply just text values. Further down we define what packages are needed to build our derivation, in the "buildInputs" section. We then have different phases for setting up our build environment, building our package, and copying it to our build output. (For this example the phases is overkill as everything could be done in one phase, but this is just to show some of the capabilities)

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

#### Making a shell environment

It would be nice to have a real shell environment to play around in, this is where the devShells comes into play. In here we are passing the function mkShell to the devShells output with the name default. The mkShell function is essentially a mkDerivation with some defaults already defined that removes required boilerplate code. In the end we do not need to define loads of different attributes and can easily define the packages we want to have available in the development shell using "packages", and also define some additional shell commands that will run when we initialize the shell environment. We are also able to set any attributes that is available in mkDerivation, but this is not required.

```Nix {linsNos=true}
devShells.default = pkgs.mkShell {
  packages = with pkgs; [
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
```

In the example above we define packages that will be available in the shell environment and a shell hook to symlink the theme used to a folder in the current directory.

## Using the flake

After we have configured the flake we also need to know how to use it, the easiest commands to understand would be to use nix develop, nix build and nix run. These all ensure that the current state of the project is build and supply different ways to interact with the output.

### How does Nix handle build artifacts

Everything in nix is saved to nix store, for most people this is located at /nix/store and everything is symlinked to wherever it is needed. This is also the case for build artifacts that is compiled using Nix. When things are build in nix using any commands they are build and put into the nix store as a immutable object(s) then these immutable objects are linked to the folder in question where it has been build under "./results"

The reason we like this extra complexity is that we ensure that the build artifacts will always be the same if the state of the repo is the same, and the artifacts cannot have changes made to them after they have been build.

### Nix build

Nix build is the easiest to understand, when we run nix build we run whatever is in the packages.default derivation. As with any function that builds the artifacts are put into the nix store, and symlinked to the local "./results" folder. The output in our case is the files used to host this blog, but it can also be binaries, text files or whatever you define in the packages section.

### Nix develop

This command is used to ensure that we have a build environment, this runs through the content we have defined in devShells.default installs all of the packages defined in our nix store, and then symlinks it to our PATH. This ensures that we can run whatever we are developing with the correct environment, a good example would be packages for python being available without having to make a venv environment that needs to be maintained.

### Nix run

This command can ensure that we can run a application in a specified way in the correct environment, a example could be that we have tests that we need run often, it ensures that we do not have to enter into our `nix develop` environment every time we are to run the test suite.
