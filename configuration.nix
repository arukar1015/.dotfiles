# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  secrets = import ./wifi_secret.nix;
in
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  # 【削除】Nvidia用のカーネルパラメータを削除しました

  networking.hostName = "nixos"; # Define your hostname.
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Tokyo";

  # Select internationalisation properties.
  i18n.defaultLocale = "ja_JP.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "ja_JP.UTF-8";
    LC_IDENTIFICATION = "ja_JP.UTF-8";
    LC_MEASUREMENT = "ja_JP.UTF-8";
    LC_MONETARY = "ja_JP.UTF-8";
    LC_NAME = "ja_JP.UTF-8";
    LC_NUMERIC = "ja_JP.UTF-8";
    LC_PAPER = "ja_JP.UTF-8";
    LC_TELEPHONE = "ja_JP.UTF-8";
    LC_TIME = "ja_JP.UTF-8";
  };

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-mozc
      fcitx5-gtk
      fcitx5-configtool
    ];
    fcitx5.waylandFrontend = true;
  };

  environment.variables = {
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
  };

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    xkb = {
      layout = "jp";
      variant = "";
    };
    # 【削除】videoDrivers = [ "nvidia" ]; を削除しました
  };

  # GNOME Desktop Environment
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # GPUの有効化（Linux標準のMesaドライバなどが使われます）
  hardware.graphics.enable = true;

  # 【完全削除】hardware.nvidia = { ... }; のブロックを丸ごと消去しました

  # Define a user account.
  users.users.touma = {
    isNormalUser = true;
    description = "touma";
    password = "isawa"; 
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    packages = with pkgs; [
      vesktop
      notion-app-enhanced
      thonny
      brave
      zoom
      vscode
      kitty
      helix
      nixd
      nixfmt-rfc-style
      htop
      btop
      starship
      obs-studio
      micro
      microsoft-edge
    ];
    shell = pkgs.fish;
  };

  # Install base programs.
  programs.firefox.enable = true;
  programs.neovim.enable = true;
  programs.fish.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # System-wide packages
  environment.systemPackages = with pkgs; [
    brave
    notion
    gnome-tweaks
    nordic
    papirus-icon-theme
    gnomeExtensions.user-themes
    gnomeExtensions.just-perfection
    git
    rustdesk
  ];

  fonts = {
    packages = with pkgs; [
      noto-fonts-cjk-serif
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      hackgen-nf-font
      (nerdfonts.override { fonts = [ "Iosevka" ]; })
    ];
    fontDir.enable = true;
    fontconfig = {
      defaultFonts = {
        serif = [ "Noto Serif CJK JP" ];
        sansSerif = [ "Noto Sans CJK JP" ];
        monospace = [
          "Iosevka Nerd Font"
          "HackGen Console NF"
          "Noto Color Emoji"
        ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

	# --- 枠無しKittyの自動起動設定 ---
  environment.etc."xdg/autostart/kitty-frameless.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Kitty Frameless
    Exec=${pkgs.kitty}/bin/kitty -o hide_window_decorations=yes -o dynamic_background_opacity=yes -o watcher=/home/touma/.dotfiles/scripts/kitty_watcher.py
    X-GNOME-Autostart-enabled=true
  '';

  system.stateVersion = "24.11"; 
}
