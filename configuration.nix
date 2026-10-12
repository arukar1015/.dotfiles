# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, ... }:

let
  # Meltype (Linux プレビュー版 / IBus エンジン)
  meltype = pkgs.callPackage ./meltype.nix { };

  antigravityFHS = pkgs.buildFHSEnv {
    name = "antigravity";
    targetPkgs = pkgs: (with pkgs; [
      # 基本ランタイム
      glibc
      zlib
      openssl
      udev
      alsa-lib

      # GUI / Electron 関連ライブラリ
      gtk3
      nss
      nspr
      mesa
      libGL
      libdrm
      cairo
      pango
      atk
      gdk-pixbuf
      dbus
      cups

      # X11 関連
      libx11
      libxcomposite
      libxdamage
      libxext
      libxfixes
      libxrandr
      libxcb
      libxcursor
      libxi
      libxrender
      libxtst
      libxscrnsaver
    ]);
    # 実行ファイルのパスを指定（自分の配置場所に合わせる）
    runScript = "/home/your-username/.local/bin/antigravity-bin";
  };
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

  # wayVNC port
  networking.firewall.allowedTCPPorts = [5900];

  # dengen kanri daemon mukouka
  services.power-profiles-daemon.enable = false;
  # 
  services.nscd.enableNsncd = false;

  services.sunshine = {
    enable = true;
    autoStart = true; # optical : starts sunshine automatically on login
    capSysAdmin = true;
    openFirewall = true;
  };
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

  # --- 日本語入力 (IBus + Mozc) の設定 ---
  i18n.inputMethod = {
    enable = true;
    type = "ibus";
    ibus.engines = [ meltype ];
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
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "touma";
  
  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
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
    hashedPasswordFile = "/etc/nixos/secrets/touma-password";
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
      nixfmt
      htop
      btop
      starship
      obs-studio
      micro
      microsoft-edge
      inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default
      remmina
      wayvnc
      wofi
      lm_sensors
    ];
    shell = pkgs.fish;
  };

  # Install base programs.
  programs.firefox.enable = true;
  programs.neovim.enable = true;
  programs.fish.enable = true;
  programs.hyprland.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # System-wide packages
  environment.systemPackages = with pkgs; [
    inputs.caelestia-shell.packages.${pkgs.stdenv.hostPlatform.system}.default
    brave
    notion
    gnome-tweaks
    nordic
    papirus-icon-theme
    gnomeExtensions.user-themes
    gnomeExtensions.just-perfection
    git
    rustdesk
    antigravityFHS
    # --- 自作コマンド「sys-update」の作成 ---
    (writeShellScriptBin "arkr-autorebuild" ''
      # 【修正】一番初めに確実に .dotfiles に移動する
      cd ~/.dotfiles || { echo "❌ ~/.dotfiles ディレクトリが見つかりません。"; exit 1; }

      echo "🔍 1. 変更をGitに登録しています..."
      git add .

      echo "🔍 2. Flakeのチェック (flake check) を実行中..."
      # flake check が成功した時だけ次に進む (失敗したら else へ)
      if nix flake check; then
        echo "✅ チェック成功！システムのビルドと適用を開始します..."
        
        # リビルドが成功した時だけ次に進む
        if sudo nixos-rebuild switch --flake .#nixos; then
          echo "🚀 ビルド＆適用が成功しました！"
          echo "⚠️ 5秒後に自動的に再起動します... (やめる場合は Ctrl+C を押してください)"
          sleep 5
          sudo reboot
        else
          echo "❌ リビルドに失敗しました。再起動せずに停止します。"
          exit 1
        fi
        
      else
        echo "❌ Flakeの構文チェックでエラーが出ました。処理を停止します。"
        exit 1
      fi
    '')
    # --- 自作コマンドのプログラム本体 ---
    (writeShellScriptBin "arkr-wifimode" ''
      COMMAND=$1
      MODE=$2
      if [ "$COMMAND" = "list" ]; then
        echo "📶 Available Wi-Fi Modes:"
        echo "  home - Default Mode (Home/Normal)"
        echo "  dhu  - Digital Hollywood University Mode"
      elif [ "$COMMAND" = "switch" ]; then
        if [ "$MODE" = "dhu" ]; then
          echo "🔄 Switching to DHU mode..."
          sudo /run/current-system/specialisation/dhu/bin/switch-to-configuration test
          echo "✅ Switched to DHU mode successfully!"
        elif [ "$MODE" = "home" ]; then
          echo "🔄 Switching to Home mode..."
          sudo /run/current-system/bin/switch-to-configuration test
          echo "✅ Switched to Home mode successfully!"
        else
          echo "❌ Error: Unknown mode '$MODE'."
          echo "💡 Use 'wifimode list' to see available modes."
        fi
      else
        echo "🛠️ Usage: wifimode {list | switch <mode>}"
      fi
    '')
  ];

  fonts = {
    packages = with pkgs; [
      noto-fonts-cjk-serif
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      hackgen-nf-font
      nerd-fonts.iosevka
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
# nix gc auto remove
# --- ゴミ箱の自動お掃除設定 ---
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
  system.stateVersion = "24.11"; 
# ==========================================
  # ネットワーク切り替え (Specialisation) & 自作コマンド設定
  # ==========================================

  # 1. 大学用(DHU)モードの定義
  specialisation = {
    dhu.configuration = {
      system.nixos.tags = [ "dhu" ]; # 起動時のメニューに「dhu」というタグがつきます
      networking.domain = "dh-mr.akist.dhw.co.jp";
      # （必要に応じて、ここに大学用のプロキシや固定IP設定を追加できます）
    };
  };
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
    zlib
    openssl
    curl
    glibc
  ];
}
