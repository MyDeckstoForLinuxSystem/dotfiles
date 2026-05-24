{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # ─────────────────────────────────────────────
  # ЗАГРУЗЧИК
  # ─────────────────────────────────────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Оставляем только 2 последних поколения в меню загрузки
  boot.loader.systemd-boot.configurationLimit = 2;

  # ─────────────────────────────────────────────
  # СЕТЬ И ЛОКАЛИЗАЦИЯ
  # ─────────────────────────────────────────────
  networking.hostName = "nixos-gaming-laptop";
  networking.networkmanager.enable = true;
  time.timeZone = "Europe/Kyiv";
  i18n.defaultLocale = "ru_RU.UTF-8";

  # ─────────────────────────────────────────────
  # AMD GPU
  # Если окажется NVIDIA — закомментируй этот блок
  # и добавь отдельный nvidia-блок
  # ─────────────────────────────────────────────
  services.xserver.videoDrivers = [ "amdgpu" ]; # Загружает правильный DRM-драйвер

  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Обязательно для Steam и 32-битных игр
    extraPackages = with pkgs; [
      amdvlk        # Официальный AMD Vulkan-драйвер (дополняет mesa)
      rocm-opencl-icd # OpenCL для AMD — нужен некоторым играм и утилитам
    ];
    extraPackages32 = with pkgs; [
      driversi686Linux.amdvlk # 32-битная версия amdvlk для Steam
    ];
  };

  # ─────────────────────────────────────────────
  # HYPRLAND + SDDM
  # ─────────────────────────────────────────────
  programs.hyprland = {
    enable = true;
    xwayland.enable = true; # Поддержка X11-приложений в Wayland
  };

  # Экран входа с поддержкой Wayland
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # dconf нужен GTK-приложениям (Firefox, Telegram) для тем и настроек
  programs.dconf.enable = true;

  # ─────────────────────────────────────────────
  # ПЕРЕМЕННЫЕ ОКРУЖЕНИЯ WAYLAND
  # ─────────────────────────────────────────────
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";          # Включает нативный Wayland в Electron-приложениях
    XCURSOR_THEME = "Bibata-Modern-Classic"; # Единый курсор во всех приложениях
    XCURSOR_SIZE = "24";
    # Говорим Vulkan использовать RADV (mesa) вместо amdvlk по умолчанию.
    # RADV обычно быстрее в играх; amdvlk остаётся как запасной вариант.
    AMD_VULKAN_ICD = "RADV";
  };

  # ─────────────────────────────────────────────
  # ШРИФТЫ
  # ─────────────────────────────────────────────
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
  ];

  # ─────────────────────────────────────────────
  # ЗВУК — PIPEWIRE
  # ─────────────────────────────────────────────
  security.rtkit.enable = true; # Даёт PipeWire реалтайм-приоритет
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;      # Совместимость с PulseAudio API
    wireplumber.enable = true; # Менеджер сессий, улучшает стабильность
  };

  # ─────────────────────────────────────────────
  # BLUETOOTH
  # ─────────────────────────────────────────────
  hardware.bluetooth.enable = true;
  services.blueman.enable = true; # Добавляет blueman-applet и daemon — НЕ добавляй blueman в systemPackages!

  # ─────────────────────────────────────────────
  # ИГРОВОЙ СТЕК
  # ─────────────────────────────────────────────
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  # Gamescope — улучшает fullscreen, frame pacing, работает как мини-композитор для игр
  programs.gamescope.enable = true;

  # Gamemode — при запуске игры временно снижает приоритет фоновых процессов
  programs.gamemode = {
    enable = true;
    enableRenice = true; # Позволяет gamemode менять nice-значения процессов
  };

  # Управление профилями питания (performance / balanced / power-saver)
  services.power-profiles-daemon.enable = true;

  # ─────────────────────────────────────────────
  # ОПТИМИЗАЦИЯ СИСТЕМЫ
  # ─────────────────────────────────────────────
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50; # Используем до 50% RAM как сжатый swap
  };

  boot.kernel.sysctl = {
    "vm.max_map_count" = 2147483642; # Предотвращает вылеты тяжёлых игр (требование многих AAA)
  };

  # ─────────────────────────────────────────────
  # NIX — СБОРЩИК МУСОРА И ОПТИМИЗАЦИЯ
  # ─────────────────────────────────────────────
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.auto-optimise-store = true; # Дедупликация файлов в nix store

  # FIX: было 7d — слишком агрессивно при configurationLimit = 2.
  # 14d даёт запас, чтобы bootloader успел почистить phantom-записи
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # ─────────────────────────────────────────────
  # SSD
  # ─────────────────────────────────────────────
  services.fstrim.enable = true; # Периодический TRIM — обязателен для здоровья SSD

  # ─────────────────────────────────────────────
  # FLATPAK (для Sober/Roblox)
  # ─────────────────────────────────────────────
  services.flatpak.enable = true;

  # ─────────────────────────────────────────────
  # ПОЛЬЗОВАТЕЛЬ
  # ─────────────────────────────────────────────
  users.users.kirill = {
    isNormalUser = true;
    description = "Kirill";
    extraGroups = [ "networkmanager" "wheel" "video" ];
  };

  nixpkgs.config.allowUnfree = true; # Разрешаем Steam, Discord и другие несвободные пакеты

  # ─────────────────────────────────────────────
  # ПАКЕТЫ
  # ─────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # — Терминал и базовые утилиты —
    kitty
    git
    fastfetch
    wget
    curl

    # — Окружение Hyprland —
    waybar           # Панель задач
    swww             # Анимированные обои
    rofi-wayland     # Лаунчер приложений
    mako             # Уведомления

    # — FIX: polkit-агент ОБЯЗАТЕЛЕН для Hyprland —
    # Без него GUI-запросы sudo (pkexec, монтирование) просто зависнут.
    # Добавь в hyprland.conf: exec-once = lxqt-policykit-agent
    lxqt.lxqt-policykit

    # — Курсор (FIX: без этого курсор будет дефолтным X11-крестиком) —
    bibata-cursors

    # — Игровой софт —
    wineWowPackages.staging # Wine с последними патчами для Windows-игр
    protonup-qt             # Обновлялка версий Proton
    lutris                  # Лаунчер для GOG/игр с кастомными runner'ами
    bottles                 # Удобный Wine-менеджер
    mangohud                # Оверлей FPS/температур. Запуск: mangohud gamemoderun %command%
    heroic                  # Epic Games / GOG лаунчер

    # — Vulkan / OpenGL утилиты —
    vulkan-tools  # vulkaninfo — проверить что Vulkan работает
    mesa-demos    # glxgears, glxinfo

    # — Повседневный софт —
    firefox
    telegram-desktop

    # — Minecraft —
    prismlauncher

    # — Системные утилиты —
    pavucontrol   # GUI для управления громкостью PipeWire/Pulse
    brightnessctl # Управление яркостью (нужен для биндов в Hyprland)
    # blueman убран отсюда — он уже подключён через services.blueman.enable выше
  ];

  system.stateVersion = "24.11";
}
