# VXA-OS Server

![VXA-OS Logo](https://i.imgur.com/vmblUfr.png)

**VXA-OS Custom Server** com suporte ao banco de dados **MySQL**.
Tópico original: [Aldeia RPG](http://www.aldeiarpg.com/t13748-vxa-os-crie-seu-mmo-com-rpg-maker)

- Autor: Valentine
- Mod: Gallighanmaker (Leandro Vieira)
- Versão: 1.0.7
- Client: RPG Maker VX Ace

## Sobre
VXA-OS é uma estrutura gratuita de criação de jogos on-line 2D. Atualmente, é considerado uma versão beta e ainda está em desenvolvimento ativo. Esse repositório contém apenas o **servidor** dessa engine.

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
...

### Roadmap:
- Comandos de eventos restantes, tais como: Mostrar Escolhas, Seleção de Item, Esperar e Mover Evento
- Movimento customizado dos eventos
- Condições de início processo paralelo e início automático dos eventos no servidor
- Armas e habilidades de longo alcance
- Editor de jogadores, de switches globais etc

### Plugin/Suporte MySQL
- Reestruturado todo o script **database.rb**
- Removido arquivos binários que eram utilizados como banco de dados
- O banco de dados pode ser hospedado paralelo ao servidor, ganhando performance e escalabilidade
- O servidor grava todas as informações de contas, jogadores, bancos, switches, variaveis no banco de dados
- Self-deleted para os personagens, não ocasionando perda de dados e para futuros sistemas

### Arquivos alterados

Todas as mudanças foram comentadas para identificar e para um melhor entendimento, segue abaixo lista de scripts modificados

- Database.rb
  - Contém todas as interações do banco de dados
- Handle_data.rb
  - Alterada a função "handle_login" e "handle_new_character"
- Game_accounts.rb
  - Alterada a função "save_data"
- Structs.rb
  - Alterado os models Account e Actor
- Nova pasta **Database**
  - **Config.json** contém as configurações de conexão com o servidor MySQL
  - **vxaos_srv.sql** contém o script que cria o banco de dados e suas tabelas, por favor não alterar o arquivo, apenas se souber o que está fazendo.

### Como configurar
- Instale o Ruby [Windows](https://rubyinstaller.org/downloads/), [Linux](https://www.brightbox.com/blog/2016/01/06/ruby-2-3-ubuntu-packages/)
- Instale o servidor MySQL 5.7 [Windows](https://dev.mysql.com/downloads/mysql/5.7.html), [Linux](https://www.digitalocean.com/community/tutorials/como-instalar-o-mysql-no-ubuntu-18-04-pt)
- Renomeie o arquivo **Database/config.sample** para **Database/config.json**
- Altere o arquivo **Database/config.json** com as informações do banco de dados
  - host
  - port
  - user
  - password
- Execute o script **main.rb** pelo terminal (cmd)
  - ./main.rb
  - O Script cria automaticamente o banco de dados e suas tabelas caso não existirem e com isso será iniciado.

![Console](https://image.prntscr.com/image/wRhzM9LEQSudk_IcMw9rfg.png)

### Arquivos não monitorados

Segue abaixo lista de arquivos **não monitorados**, ou seja, podemos modificar qualquer informação desses arquivos e eles não serão enviados para o **git**. O **gitignore** foi configurado dessa forma para não interferir em outros projetos. Ao clonar o projeto **certifique-se** de adicionar seus próprios arquivos.

- Icon/*.*
- Data/*.*
- Logs/*.*
- configs.ini
- quests.ini
- motd.txt
- Database/config.json

### Discord
[Link](https://discord.gg/cVhjdsF)

### Licença
VXA-OS é uma estrutura livre de código aberto, distribuído sob uma licença muito liberal (a conhecida licença MIT). O projeto pode ser usado para quaisquer propósitos, incluindo finalidades comerciais, sem qualquer custo ou burocracia.

VXA-OS não é de domínio público e o seu criador mantém seus direitos autorais. O único requisito é que, se você usar o VXA-OS, deverá dar crédito ao criador ao incluir o aviso de direitos autorais em algum lugar de seu jogo.

Em nenhuma circunstância, o autor ou proprietário de direitos de autor poderá ser responsabilizado por quaisquer reivindicações, danos ou outras responsabilidades.

### Contato

Leandro Vieira
leandrovieira92@gmail.com