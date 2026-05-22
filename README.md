<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/2a23126b-2a51-49c0-ae96-0356f27479fc" />

<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/12eb9e44-c625-4a82-b52a-87db028f3848" />


# hyprdots

Meus dotfiles pessoais para **Hyprland** no Arch Linux.

## Instalação

```bash
git clone https://github.com/csouzape/hyprdots
cd hyprdots
chmod +x hyprdots.sh
sudo ./hyprdots.sh
```

O script apresenta um **menu interativo**:

```
  1) Instalar     — Configura Hyprland e todos os dotfiles
  2) Desinstalar  — Remove pacotes/dotfiles de forma segura
  0) Sair
```

### Desinstalação segura

A opção **2 (Desinstalar)** detecta automaticamente IDEs instaladas:

- **VS Code / VSCodium** → pacote e configurações preservados
- **Neovim** → pacote e configurações preservados

Você ainda escolhe o escopo da remoção:

```
  1) Remover apenas os dotfiles
  2) Remover pacotes instalados pelo script
  3) Remover tudo (dotfiles + pacotes)
```

## Estrutura

```
hyprdots/
├── hyprdots.sh          ← script principal (menu)
├── distro/
│   └── arch/
│       └── arch.sh      ← instalação Arch Linux
└── dots/                ← seus configs (hypr, waybar, rofi, alacritty...)
    ├── hypr/
    ├── waybar/
    ├── rofi/
    └── alacritty/
```

## ⚠️ Avisos

- **Monitores**: as configs do waybar usam nomes de monitor fixos.  
  Após instalar, rode `hyprctl monitors` e ajuste o campo `output` em `~/.config/waybar/config`.

- **VM**: não funciona corretamente em máquinas virtuais devido ao mapeamento de monitor.

- **Distribuição**: suporte apenas para Arch Linux e variantes (Manjaro, EndeavourOS).

## Requisitos

- Arch Linux (instalação mínima)
- `git` instalado
- Conexão com a internet
