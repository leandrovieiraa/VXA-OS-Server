# VXA-OS-Server

**VXA-OS Custom Server** com suporte ao banco de dados **MySQL**.
Tópico original: [Aldeia RPG](http://www.aldeiarpg.com/t13748-vxa-os-crie-seu-mmo-com-rpg-maker)

![VXA-OS Logo](https://i.imgur.com/vmblUfr.png)

- Autor: Valentine
- Mod: Gallighanmaker (Leandro Vieira)
- Versão: 1.0.8
- Client: RPG Maker VX Ace
- [Ruby + Devkit 2.5.3-1 (x64)](https://rubyinstaller.org/downloads/)

## Sobre
VXA-OS é uma estrutura gratuita de criação de jogos on-line 2D. Atualmente, é considerado uma versão beta e ainda está em desenvolvimento ativo.

## Características

### Atuais:
- 4 tipos de bate-papo
- 9 tipos de equipamento
- 13 comandos de administrador
- 3 comandos de moderador
- Sistema de batalha global no servidor
- Senhas protegidas com a função criptográfica MD5
- 99% dos comandos de eventos no servidor
- Eventos comuns no servidor
- Resolução configurável
- Switches globais
- Biblioteca de rede EventMachine
- Sistema de amigos
- Sistema de missões
- Editor de contas
- Teletransporte
- Paperdolls
- Grupo
- Minimap
- PvP
- Banco

### Roadmap:
- Comandos de eventos restantes, tais como: Mostrar Escolhas, Seleção de Item, Esperar e Mover Evento
- Movimento customizado dos eventos
- Condições de início processo paralelo e início automático dos eventos no servidor
- Armas e habilidades de longo alcance
- Editor de jogadores, de switches globais etc

### Suporte MySQL
- Reestruturado todo o script **database.rb**
- Removido arquivos binários que eram utilizados como banco de dados
- Banco de dados pode ser hospedado paralelo ao servidor, ganhando performance em maquinas e escalabilidade
- Grava todas as informações de contas, jogadores, bancos, switches, variaveis no banco de dados
- Self-deleted para os personagens, não ocasionando perda de dados e para futuros sistemas

### Como configurar
-
-
