{ config, pkgs, inputs, ... }:

{
  # AGS - Aylur's GTK Shell configuration
  imports = [ inputs.ags.homeManagerModules.default ];
  
  programs.ags = {
    enable = true;
    
    # Add additional packages needed for AGS
    extraPackages = with pkgs; [
      gtksourceview
      webkitgtk
      accountsservice
    ];
  };
  
  # AGS configuration files will go in ~/.config/ags/
  home.file.".config/ags/config.js".text = ''
    // AGS Configuration
    import { Bar } from "./bar.js"
    
    App.config({
      windows: [
        Bar(0), // Monitor 0 (DP-2)
        Bar(1), // Monitor 1 (DP-1)
      ],
      style: "./style.css",
    })
  '';
  
  home.file.".config/ags/bar.js".text = ''
    const hyprland = await Service.import("hyprland")
    const battery = await Service.import("battery")
    const audio = await Service.import("audio")
    const bluetooth = await Service.import("bluetooth")
    const network = await Service.import("network")
    const systemtray = await Service.import("systemtray")
    
    // Workspaces widget
    const Workspaces = (monitor) => Widget.Box({
      class_name: "workspaces",
      children: Array.from({ length: 10 }, (_, i) => i + 1).map(i => Widget.Button({
        attribute: i,
        label: `''${i}`,
        on_clicked: () => hyprland.messageAsync(`dispatch workspace ''${i}`),
        setup: self => self.hook(hyprland, () => {
          self.toggleClassName("active", hyprland.active.workspace.id === i)
          // Show only relevant workspaces per monitor
          if (monitor === 0) {
            self.visible = [1, 3, 5, 7, 9].includes(i)
          } else {
            self.visible = [2, 4, 6, 8, 10].includes(i)
          }
        }),
      })),
    })
    
    // Window title
    const ClientTitle = () => Widget.Label({
      class_name: "client-title",
      label: hyprland.active.client.bind("title"),
      max_width_chars: 50,
      truncate: "end",
    })
    
    // Clock
    const Clock = () => Widget.Label({
      class_name: "clock",
      setup: self => self.poll(1000, self => {
        const date = new Date()
        self.label = date.toLocaleTimeString("en-US", {
          hour: "2-digit",
          minute: "2-digit",
        })
      }),
    })
    
    // Volume
    const Volume = () => Widget.Button({
      class_name: "volume",
      on_clicked: () => audio.speaker.is_muted = !audio.speaker.is_muted,
      child: Widget.Icon().hook(audio.speaker, self => {
        const vol = audio.speaker.volume * 100
        const icon = [
          [101, "overamplified"],
          [67, "high"],
          [34, "medium"],
          [1, "low"],
          [0, "muted"],
        ].find(([threshold]) => threshold <= vol)?.[1]
        
        self.icon = `audio-volume-''${audio.speaker.is_muted ? "muted" : icon}-symbolic`
        self.tooltip_text = `Volume ''${Math.floor(vol)}%`
      }),
    })
    
    // Bluetooth
    const Bluetooth = () => Widget.Button({
      class_name: "bluetooth",
      on_clicked: () => Utils.execAsync("blueman-manager"),
      child: Widget.Icon({
        icon: bluetooth.bind("enabled").as(on => 
          `bluetooth-''${on ? "active" : "disabled"}-symbolic`
        ),
      }),
      setup: self => self.hook(bluetooth, self => {
        const connected = bluetooth.connected_devices.length
        self.tooltip_text = bluetooth.enabled 
          ? `Bluetooth: ''${connected} connected`
          : "Bluetooth: Off"
      }),
    })
    
    // Network
    const Network = () => Widget.Icon().hook(network, self => {
      const icon = network[network.primary || "wired"]?.icon_name
      self.icon = icon || ""
      self.visible = !!icon
    })
    
    // Battery
    const Battery = () => Widget.Box({
      class_name: "battery",
      visible: battery.bind("available"),
      children: [
        Widget.Icon({ icon: battery.bind("icon_name") }),
        Widget.Label({
          label: battery.bind("percent").as(p => `''${p}%`),
        }),
      ],
    })
    
    // System tray
    const SysTray = () => Widget.Box({
      class_name: "systray",
      children: systemtray.bind("items").as(items => items.map(item => Widget.Button({
        child: Widget.Icon({ icon: item.bind("icon") }),
        on_primary_click: (_, event) => item.activate(event),
        on_secondary_click: (_, event) => item.openMenu(event),
        tooltip_markup: item.bind("tooltip_markup"),
      }))),
    })
    
    // Main bar
    export const Bar = (monitor = 0) => Widget.Window({
      name: `bar-''${monitor}`,
      class_name: "bar",
      monitor,
      anchor: ["top", "left", "right"],
      exclusivity: "exclusive",
      child: Widget.CenterBox({
        start_widget: Widget.Box({
          spacing: 8,
          children: [
            Workspaces(monitor),
            ClientTitle(),
          ],
        }),
        center_widget: Clock(),
        end_widget: Widget.Box({
          hpack: "end",
          spacing: 8,
          children: [
            Volume(),
            Bluetooth(),
            Network(),
            Battery(),
            SysTray(),
          ],
        }),
      }),
    })
  '';
  
  home.file.".config/ags/style.css".text = ''
    * {
      all: unset;
      font-family: "JetBrainsMono Nerd Font", "FiraCode Nerd Font";
      font-size: 14px;
    }
    
    .bar {
      background-color: rgba(30, 30, 46, 0.8);
      backdrop-filter: blur(10px);
      color: #cdd6f4;
      padding: 4px 10px;
      border-radius: 0;
    }
    
    .workspaces button {
      padding: 4px 10px;
      margin: 0 2px;
      border-radius: 6px;
      background-color: transparent;
      color: #585b70;
      transition: all 0.2s;
    }
    
    .workspaces button.active {
      background: linear-gradient(45deg, rgba(51, 204, 255, 0.8), rgba(0, 255, 153, 0.8));
      color: #1e1e2e;
      font-weight: bold;
    }
    
    .workspaces button:hover {
      background-color: rgba(88, 91, 112, 0.4);
      color: #cdd6f4;
    }
    
    .client-title {
      margin-left: 10px;
      color: #cdd6f4;
    }
    
    .clock {
      font-weight: bold;
      color: #89dceb;
      font-size: 15px;
    }
    
    .volume, .bluetooth {
      padding: 4px 8px;
      margin: 0 2px;
      border-radius: 6px;
      background-color: transparent;
      transition: all 0.2s;
    }
    
    .volume:hover, .bluetooth:hover {
      background-color: rgba(88, 91, 112, 0.4);
    }
    
    .battery {
      padding: 4px 8px;
      margin: 0 2px;
      border-radius: 6px;
      color: #a6e3a1;
    }
    
    .systray button {
      padding: 4px 8px;
      margin: 0 2px;
      border-radius: 6px;
      transition: all 0.2s;
    }
    
    .systray button:hover {
      background-color: rgba(88, 91, 112, 0.4);
    }
  '';
}
