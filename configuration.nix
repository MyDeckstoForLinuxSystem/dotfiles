{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Загрузчик UEFI
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

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
  };

  # Включение Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; 
    dedicatedServer.openFirewall = true; 
  };

  # --- БЛОК ОПТИМИЗАЦИИ (ZRAM + GAMEMODE) ---
  zramSwap = {
    enable = true;
    algorithm = "zstd";      
    memoryPercent = 50;      
  };

  programs.gamemode.enable = true;
  services.power-profiles-daemon.enable = true;

  boot.kernel.sysctl = {
    "vm.max_map_count" = 2147483642; # Защита тяжелых игр от вылетов
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

    # Игровой софт и запуск Windows-игр
    wineWowPackages.staging 
    protonup-qt             
    lutris                  
    bottles                 
    mangohud                # Тот самый оверлей с FPS, температурами и нагрузкой в углу экрана

    # Повседневный софт
    firefox
    telegram-desktop
  ];

  # Оптимизация памяти Nix-хранилища
  nix.settings.auto-optimise-store = true;

  system.stateVersion = "24.11";
}
