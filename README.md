# Nøughty Linux 🐧

**Nøughty Linux** is an unconventional Linux desktop experience that combines Ubuntu's familiarity and broad hardware compatibility with Nix's declarative configuration and vast software library all wrapped in a user-friendly interface that requires zero Nix knowledge.

> Maximum desktop. Minimum effort.

***Development Status:*** `pre-alpha` 💣

## Installation Journey 🧑‍💻
1. Standard Ubuntu Server installation
2. Bootstrap Nøughty Linux
```shell
curl -fsSL https://noughtylinux.org/bootstrap | bash
```
3. Reboot into Nøughty Linux

## Project Overview ⛰️

[**Ubuntu**](https://ubuntu.com) provides hardware drivers, kernel, and system foundation. A [**Nix flake**](https://zero-to-nix.com/concepts/flakes/) provides curated terminal environment, desktop shell, applications, development tools and a [**TOML**](https://toml.io) configuration gives users meaningful control without complexity.

### Key Technologies ⚙️

- [**Ubuntu**](https://ubuntu.com): Hardware compatibility and driver management
- [**Determinate Nix**](https://docs.determinate.systems/determinate-nix/): Performance optimised [Nix](https://zero-to-nix.com/concepts/nix/)
- [**system-manager**](https://github.com/numtide/system-manager): Manage system config using Nix on any distro
- [**nix-system-graphics**](https://github.com/soupglasses/nix-system-graphics): Run graphics accelerated programs built with Nix on any Linux distribution
- [**home-manager**](https://github.com/nix-community/home-manager): Manage a user environment using Nix
- [**kmscon**](https://github.com/Aetf/kmscon): Linux KMS/DRM based virtual Console Emulator
- [**nala**](https://gitlab.com/volian/nala): Beautiful and fast alternative to `apt-get`
- [**just**](https://just.systems/): a command runner
- [**TOML**](https://toml.io): a config file format for humans
- [**Catppuccin**](https://catppuccin.com/): soothing pastel theme for the high-spirited!

### User Experience Design 👤

#### Target Audience
- 🥇**Primary**: Linux enthusiasts wanting contemporary tools with a tightly integrated experience
- 🥈**Secondary**: Give me the bling without the effort eye candy hunters
- 🥉**Tertiary**: Users interested in Nix ecosystem without NixOS commitment

#### Configuration Philosophy
- **Opinionated defaults**: Excellent *"out-of-box"* experience
- **User agency**: Meaningful choices without overwhelming options
- **Zero Nix knowledge**: TOML configuration and simple CLI
- **Power user escape hatch**: Advanced users can add custom Nix configuration via `home-manager/user/custom.nix`
- **Theme consistency**: Catppuccin color palette exposed for custom application theming

### Scope 🔭

- Catppuccin only.
- Wayland only.
- No full desktop environments.
- A few well chosen configuration options, not exhaustive control.
- Minimal project hosting requirements. Ideally nought.

## Why *"Nøughty"*

The name plays on *"nought"* (British English for zero) while embracing the rebellious spirit of doing things differently.
For the developer audience, *noughty* creates a parallel to programming's truthy/falsy concepts because Nøughty Linux is *nought* a distro and unlike traditional Linux distributions, distributes *nought* ISOs 📀

This architectural choice has the following benefits:

- Nought ISO maintenance burden
- Nought hardware compatibility testing
- Nought installation media versioning
- Nought distribution infrastructure costs
- Nought security maintenance

The name embodies the project's core philosophy: providing maximum value from minimum user investment.
Users contribute *nought* in terms of complex configuration, system administration, or Nix expertise, yet receive a fully contemporary, declaratively managed terminal environment and desktop shell.

## Roadmap 🗺️

See [TODO.md](TODO.md) for the roadmap and work in progress 🚧
