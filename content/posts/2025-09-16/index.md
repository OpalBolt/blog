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
I have defined a few inputs, these to define where our dependencies are coming from. Most notable of all i have defined the theme repo i am using.

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

This is a easy way to include data that we normally add using git sub-modules, but instead we get nix to handle downloading the data and making it available through the nix store. This is also a way for us to easily go back to eailer versions of said repo.
Having Nix handle these theme github repos also ensures that we can have the same versions when we test and build, as we will be building using a Github action.

Further down in the code we have the outputs, for the outputs we define that we would like to have self, nixpkgs and flake-utils available directly, and have all other inputs available in-directly.

```Nix
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
        pkgs = import nixpkgs { inherit system; };
        selectedTheme = "blowfish";
        themeSource = builtins.getAttr selectedTheme inputs;
      in
```
