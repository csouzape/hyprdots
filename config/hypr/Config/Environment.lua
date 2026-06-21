-- Variáveis de ambiente do Hyprland
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")



hl.env("GTK_THEME", "Materia-dark") -- Force gtk theme to dark, since Hyprland doesn't support gtk4 yet and some apps look bad with light theme
hl.env("QT_QPA_PLATFORMTHEME",                "qt6ct") -- Diz para aplicações Qt pegarem tema e aparência do qt6ct.
hl.env("QT_QPA_PLATFORM",                     "wayland;xcb") -- Backend gráfico: tenta Wayland se falhar usa X11/XWayland
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR",         "1") -- Habilita o redimensionamento automático de aplicativos Qt para telas HiDPI, garantindo que eles sejam dimensionados corretamente em monitores de alta resolução.
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1") -- Desativa as decorações de janela fornecidas pelo Qt em Wayland, permitindo que o Hyprland gerencie as decorações de janela de forma consistente.

hl.env("XDG_MENU_PREFIX",      "arch-") -- Prefixo para os arquivos .desktop, para evitar conflitos com outros ambientes de desktop. O prefixo "arch-" é apenas um exemplo, você pode escolher outro prefixo se desejar.
hl.env("XDG_SESSION_TYPE",     "wayland") -- Especifica o tipo de sessão como "wayland", indicando que o ambiente de desktop está usando o protocolo Wayland em vez do X11. Isso é importante para garantir que os aplicativos e o sistema operacional saibam que estão rodando em um ambiente Wayland, o que pode afetar o comportamento de janelas, gráficos e outros aspectos do sistema.
hl.env("XDG_CURRENT_DESKTOP",  "Hyprland") -- Especifica o nome do ambiente de desktop atual como "Hyprland". Isso é importante para que os aplicativos e o sistema operacional saibam que estão rodando em um ambiente de desktop específico, o que pode afetar o comportamento de janelas, gráficos e outros aspectos do sistema. O valor "Hyprland" é apenas um exemplo, você pode escolher outro nome se desejar.
hl.env("XDG_SESSION_DESKTOP",  "Hyprland") -- Especifica o nome do ambiente de desktop para a sessão atual como "Hyprland". Isso é importante para que os aplicativos e o sistema operacional saibam que estão rodando em um ambiente de desktop específico, o que pode afetar o comportamento de janelas, gráficos e outros aspectos do sistema. O valor "Hyprland" é apenas um exemplo, você pode escolher outro nome se desejar.
hl.env("XDG_DESKTOP_PORTAL",   "xdg-desktop-portal") -- Força o portal do desktop usado pelos apps Wayland/XWayland.
hl.env("GTK_USE_PORTAL",        "1") -- Garanta que apps GTK usem a integração via portal quando disponível.