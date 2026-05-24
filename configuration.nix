{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Загрузчик UEFI
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Ограничиваем меню загрузки: останется только текущая сборка и 1 прошлая
  boot.loader.systemd-boot.configurationLimit = 2;

  # Сеть и локализация
  networking.hostName = "nixos-gaming-laptop";
  networking.networkmanager.enable = true;
  time.timeZone = "Europe/Kyiv";
  i18n.defaultLocale = "ru_RU.UTF-8";

  # Графическая оболочка Hyprland
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Экран приветствия (Display Manager) — чтобы загружаться сразу в графику, а не в консоль
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # Окружение и переменные для Wayland
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1"; # Заставляет Discord, Telegram и Chrome работать плавно через Wayland
  };

  # Правильная настройка шрифтов (теперь иконки в Hyprland не сломаются)
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
  ];

  # Ускорение графики (критично для Proton и игр)
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Обязательно для 32-битных игр в Steam
  };

  # Звук через PipeWire
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true; # Улучшает стабильность звука
  };

  # Включение Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  # Gamescope — улучшает fullscreen, frame pacing и FPS в играх
  programs.gamescope.enable = true;

  # --- БЛОК ОПТИМИЗАЦИИ (ZRAM + GAMEMODE) ---
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  programs.gamemode = {
    enable = true;
    enableRenice = true; # Больше контроля над приоритетами процессов
  };

  services.power-profiles-daemon.enable = true;

  boot.kernel.sysctl = {
    "vm.max_map_count" = 2147483642; # Защита тяжелых игр от вылетов
  };

  # Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # SSD trim — обязательно для здоровья SSD
  services.fstrim.enable = true;

  # Flatpak — нужен для Sober (Roblox)
  services.flatpak.enable = true;

  # Flakes и nix-command — мастхэв для NixOS
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Автоматическая чистка старого софта раз в неделю
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # Пользователь Kirill
  users.users.kirill = {
    isNormalUser = true;
    description = "Kirill";
    extraGroups = [ "networkmanager" "wheel" "video" "gamemode" ];
  };

  # Разрешаем несвободные пакеты
  nixpkgs.config.allowUnfree = true;

  # Список программ
  environment.systemPackages = with pkgs; [
    # Терминал и утилиты
    kitty
    git
    fastfetch
    wget
    curl

    # Окружение Hyprland
    waybar
    swww
    rofi-wayland
    mako

    # Игровой софт и запуск Windows-игры
    wineWowPackages.staging
    protonup-qt
    lutris
    bottles
    mangohud    # Оверлей с FPS, температурами и нагрузкой (запуск: mangohud gamemoderun %command%)
    heroic      # Epic/GOG лаунчер

    # Vulkan/OpenGL утилиты
    vulkan-tools
    mesa-demos

    # Повседневный софт
    firefox
    telegram-desktop

    # Minecraft
    prismlauncher

    # Системные утилиты
    pavucontrol   # Управление громкостью
    brightnessctl # Управление яркостью экрана
    blueman       # Управление Bluetooth
  ];

  # Оптимизация памяти Nix-хранилища
  nix.settings.auto-optimise-store = true;

  system.stateVersion = "24.11";
}
