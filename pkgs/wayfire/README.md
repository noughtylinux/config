# Wayfire 0.10.0 Local Packages

## Structure

```
pkgs/wayfire/
├── default.nix          # Wayfire compositor 0.10.0
├── plugins.nix          # wayfirePlugins scope (makeScope)
├── wrapper.nix          # Wrapper to set plugin paths
├── wcm.nix              # Wayfire Config Manager 0.10.0
└── wf-shell.nix         # Wayfire shell/panel 0.10.0
```

## Usage

### 1. Basic Wayfire (without plugins)

```nix
environment.systemPackages = [ pkgs.wayfire ];
```

### 2. Wayfire with plugins (using wrapper)

```nix
environment.systemPackages = [
  (pkgs.callPackage ./pkgs/wayfire/wrapper.nix {
    wayfire = pkgs.wayfire;
    plugins = with pkgs.wayfirePlugins; [
      wcm
      wf-shell
    ];
  })
];
```

### 3. Individual plugins

```nix
environment.systemPackages = with pkgs.wayfirePlugins; [
  wcm        # Wayfire Config Manager
  wf-shell   # Wayfire panel
];
```

## Adding More Plugins

To add additional Wayfire plugins:

1. Create `pkgs/wayfire/<plugin-name>.nix` following the pattern of `wcm.nix`
2. Add the plugin to `pkgs/wayfire/plugins.nix`:

```nix
{
  wcm = callPackage ./wcm.nix { };
  wf-shell = callPackage ./wf-shell.nix { };
  your-plugin = callPackage ./your-plugin.nix { };  # Add here
}
```

## How It Works

The `wayfirePlugins` namespace is created using `lib.makeScope`, which:
- Creates a self-referential scope where plugins can depend on each other
- Allows plugins to reference `wayfire` from the same scope
- Matches the upstream nixpkgs structure for compatibility

The wrapper uses `symlinkJoin` to:
- Combine wayfire and all selected plugins into one derivation
- Set `WAYFIRE_PLUGIN_PATH` so Wayfire can discover plugin `.so` files
- Set `WAYFIRE_PLUGIN_XML_PATH` so Wayfire can find plugin metadata
