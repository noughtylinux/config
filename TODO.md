# TODO

## bootstrap / flake / justfile

- [x] Ubuntu pre- and post- recipes
- [x] Remove username and hostname from the `config.toml`
- [x] Install `nala` and use it for `apt` operations
- [ ] Put guard rails up to prevent installing on Ubuntu Desktop
- [x] Consolidate duplicated Ubuntu configuration tasks
- [ ] Plymouth
- [ ] Add `[desktop]` section and use `shell` to enable desktop features
- [ ] Add `[boot]` section to set Kernel, GRUB and Plymouth options
- [x] Pipewire & WirePlumber
- [x] CUPS
- [x] BlueZ
- [x] Clean up `justfile`. Maybe break it up
- [x] Relocate `bootstrap.sh` in the config repository
- [x] Add `tarball` command to `justfile`
- [ ] Use tarballs as the distribution/update mechanism

## Modules

- [ ] ~~Create a noughtyConfig module~~ - *This over complicated the configuration*
- [x] Expose Catppuccin colors to use in other themes
- [ ] What existing style/theme modules might be suitable?

## Home Manager

- [x] Add atuin
- [x] Rename `nore` to `nook`
- [x] Rename `norf` to `nout`
- [x] Create `nope` to `setsid` things
- [x] Add all the dconf tweaks from my nix-config for theme and fonts
- [x] Add `nh search` text to config headers
- [x] Hide crufty desktop entries
- [x] Make `halp` find help flags other that `--help`
- [x] Choose a browser
- [ ] Choose a terminal editor
- [x] User defined packages to install
- [x] User owned custom Nix config
- [x] Pin Nixpkgs in `nosh` et al to the stable channel
- [ ] Create `nash` a Nix hash getter

## System Manager

- [x] AppArmor profile for SUID binaries in the Nix store
- [x] AppArmor profile for bwrap
- [x] Add screen clearing to `agetty`
- [ ] ~~Use `agetty` in `kmscon` from Nixpkgs~~ - *didn't work*
- [x] Enable `kmscon` on all VTs
- [x] Add Symbola and Nerd Font symbols fonts in system-manager
- [x] Theme kernel colors with Catppuccin
- [ ] Theme GRUB
- [ ] Display Manager
- [x] Fix `sudo` finding executables from the user profile
- [x] Fix kmscon restart on theme change
- [x] Fix kernel VT colour not preserving on reboot/shutdown

# Challenges

## SUID sandbox and bwrap

```
[31341:31341:0611/040512.056408:FATAL:setuid_sandbox_host.cc(158)] The SUID sandbox helper binary was found, but is not configured correctly. Rather than run without sandboxing I'm aborting now. You need to make sure that /nix/store/98a01h4pabdqsbf6ghny3chzgpp3z5h4-chromium-83.0.4103.97-sandbox/bin/__chromium-suid-sandbox is owned by root and has mode 4755.
```

- 🐛 **[Google Chrome complains that its SUID sandbox isn't configured correctly](https://github.com/NixOS/nixpkgs/issues/89599)**

The Ubuntu kernel is hardened and requires AppArmor profiles for applications that use the SUID sandbox.
This includes:
- Brave
- Chrome
- Chromium
- Discord
- Microsoft Edge
- Vivaldi

...and many more applications based on Chromium, such as Electron apps.

Using `sudo sysctl kernel.unprivileged_userns_clone=1` may have been disabled in
recent Ubuntu releases, so AppArmor profiles appear to be the only option.
Ubuntu ships nearly 150 AppArmor profiles in `/etc/apparmor.d` and they can often
be repurposed to create profiles for the Nix store.

The post explaining [a permissive AppArmor profile](https://github.com/NixOS/nixpkgs/issues/89599#issuecomment-2922388555) was the clue to getting this working.

The other option, that worked, was to use an [Ubuntu mainline kernel](https://kernel.ubuntu.com/mainline/)
due to their relaxed kernel hardening. The other drawback of using a mainline
kernel is hardware support regressions, such a panel backlight not working
correctly on my AMD Ryzen 5 PRO 5650U powered ThinkPad X13.
