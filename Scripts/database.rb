#==============================================================================
# ** Database
#------------------------------------------------------------------------------
# Autor: Valentine
# MySQL Plugin: Gallighanmaker
#==============================================================================

module Database

	def self.generate_mysql_client(use_database)
		# Lê o arquivo de configuração referente ao banco de dados.
		begin  
			config = JSON.parse(File.read("Database/config.json", mode: 'r'))
		rescue
			raise "Erro ao ler o arquivo de configuracao.".colorize(:red)
		end

		# Conecta no banco de dados usando as informações carregadas do arquivo config.
		if(!use_database)
			mysql_client = Mysql2::Client.new(:host => config["host"], :port => config["port"], :username => config["user"], :password => config["pass"])
		else
			mysql_client = Mysql2::Client.new(:host => config["host"], :port => config["port"], :username => config["user"], :password => config["pass"], :database => "vxaos_srv")
		end

		# Retorna o objeto de conexao funcional
		return mysql_client
	end

	def self.create_database
		# Objeto mysql client
		mysql_client = generate_mysql_client(false)

		#Cria o banco de dados caso não existir e também cria as tabelas
		sql_file = File.read("Database/vxaos_srv.sql", mode: 'r').split(';')
		sql_file.each do |line|
			mysql_client.query(line)
		end	

		# Fecha a conexão com o banco de dados
		mysql_client.close()
	end

	def self.create_account(user, pass, email)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)

		# Consulta para criar a conta de usuario
		query_create_account = "INSERT INTO 
								accounts (
									username, 
									password, 
									email, 
									account_group) 
								VALUES ('#{user}', '#{pass}', '#{email}', #{Constants::GROUP_STANDARD})"

		# Executa a consulta
		command_create = mysql_client.query(query_create_account)
		
		# Fecha a conexão com o banco de dados
		mysql_client.close()

		# Apos criar a conta, criar e atribuir o "bank".
		acc = load_account(user)
		create_bank(acc.account_id)
	end

	def self.load_account(user)
		# Cria o objeto "account" referente ao arquivo struct.rb
		account = Account.new	
	
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)
		
		# Consulta para listar a conta de usuario
		query_load_account = "SELECT * FROM accounts WHERE username = '#{user}'"

		# Executa o comando
		command_load = mysql_client.query(query_load_account)
		
		# Loop para atribuir os dados de usuario carregados na consulta
		command_load.each do |row|
			account.account_id = row["account_id"]
			account.user = row["username"]
			account.pass = row["password"]
			account.email = row["email"]
			account.group = row["account_group"]
		end
		
		# Consulta para listar os "actors" que pertencem a esse usuario
		query_load_actors_account = "SELECT actor_id, actor_slot_id FROM actors WHERE account_id = '#{account.account_id}' AND deleted = false"
		
		# Executa o comando
		command_load_actors = mysql_client.query(query_load_actors_account)
		
		# Cria um hash de actors
		actors = {}
		
		# Loop para atribuir os dados de personagem carregados na consulta	
		command_load_actors.each do |row|
			actors[row["actor_slot_id"]] = load_player(row["actor_id"])
		end
		
		# Atribui os personagens para a conta de usuario
		account.actors = actors

		# Fecha a conexão com o banco de dados
		mysql_client.close()

		# Retorna o objeto "account"
		account
	end

	def self.save_account(client)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)
				
		# Consulta para atualizar a conta de usuario
		query_update_account = "UPDATE accounts SET password = '#{client.pass}', email = '#{client.email}', account_group = #{client.group} WHERE username = '#{client.user}'"

		# Executa o comando
		command_update = mysql_client.query(query_update_account)

		# Fecha a conexão com o banco de dados
		mysql_client.close()
	end

	def self.account_exist?(user)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)

		# Consulta para checar se o usuario existe
		query_check_account = "SELECT account_id FROM accounts WHERE username = '#{user}'"

		# Executa o comando
		command_check = mysql_client.query(query_check_account)		
		if 0 == command_check.size
			return false # Usuario nao existe
		else
			return true # Usuario existe
		end

		# Fecha a conexão com o banco de dados
		mysql_client.close()
	end

	def self.create_player(client, actor_id, name, character_index, class_id, sex, params, points, account)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)

		# Cria o objeto "Actor"
		actor = Actor.new

		# Lista de atributos do "Actor"
		actor.name = name
		actor.character_name = $data_classes[class_id].graphics[sex][character_index][0]
		actor.character_index = $data_classes[class_id].graphics[sex][character_index][1]
		actor.face_name = $data_classes[class_id].graphics[sex + 2][character_index][0]
		actor.face_index = $data_classes[class_id].graphics[sex + 2][character_index][1]
		actor.class_id = class_id
		actor.sex = sex
		initial_level = $data_actors[class_id].initial_level
		actor.level = initial_level
		actor.exp = $data_classes[class_id].exp_for_level(initial_level)
		maxhp = params[Constants::PARAM_MAXHP] * 10 + $data_classes[class_id].params[Constants::PARAM_MAXHP, initial_level]  # HP Máximo
		maxmp = params[Constants::PARAM_MAXMP] * 10 + $data_classes[class_id].params[Constants::PARAM_MAXMP, initial_level]  # MP Máximo
		attack = params[2] + $data_classes[class_id].params[2, initial_level]	# Ataque
		defense = params[3] + $data_classes[class_id].params[3, initial_level] # Defesa
		intelligence = params[4] + $data_classes[class_id].params[4, initial_level] # Inteligência
		resistence = params[5] + $data_classes[class_id].params[5, initial_level]# Resistência
		agility = params[6]	+ $data_classes[class_id].params[6, initial_level] # Agilidade
		luck = params[7] + $data_classes[class_id].params[7, initial_level] # Sorte
		actor.hp = maxhp
		actor.mp = maxmp
		actor.param_base = [maxhp, maxmp, attack, defense, intelligence, resistence, agility, luck]
		actor.equips = [0, 0, 0, 0, 0, 0, 0, 0, 0]	
		actor.points = points
		actor.revive_map_id = actor.map_id = $data_system.start_map_id
		actor.revive_x = actor.x = $data_system.start_x
		actor.revive_y = actor.y = $data_system.start_y
		actor.direction = Constants::DIR_DOWN
		actor.gold = 0
		actor.items = {}
		actor.weapons = {}
		actor.armors = {}
		actor.skills = []
		$data_classes[class_id].learnings.each { |learning| actor.skills << learning.skill_id if learning.level <= initial_level  }
		actor.quests = {}
		actor.friends = []
		actor.hotbar = Array.new(MAX_HOTBAR) { Hotbar.new(0, 0) }	
		actor.switches = Array.new(MAX_PLAYER_SWITCHES, false)
		actor.variables = Array.new(MAX_PLAYER_VARIABLES, 0)
		actor.self_switches = {}

		# Consulta para criar um actor
		query_create_actor = "INSERT INTO 
								actors (
									actor_slot_id, account_id, name, character_name, character_index, face_name, face_index, class_id, sex, level, exp, 
									hp, mp, maxhp, maxmp, attack, defense, intelligence, resistence, agility, luck,
									points, revive_map_id, revive_x, revive_y, map_id, x, y, direction, gold) 
								VALUES 
								(
									#{actor_id}, #{account.account_id}, '#{actor.name}', '#{actor.character_name}', #{actor.character_index}, '#{actor.face_name}', #{actor.face_index},
									#{actor.class_id}, #{actor.sex}, #{actor.level}, #{actor.exp}, #{actor.hp}, #{actor.mp}, #{maxhp}, #{maxmp}, #{attack}, #{defense}, 
									#{intelligence}, #{resistence}, #{agility}, #{luck}, #{actor.points}, #{actor.revive_map_id}, #{actor.revive_x},
									#{actor.revive_y}, #{actor.map_id}, #{actor.x}, #{actor.y}, #{actor.direction}, #{actor.gold}
								)"
		# Executa a consulta
		command_create = mysql_client.query(query_create_actor)
		
		# Fecha a conexão com o banco de dados, pois as demais funções demandando mais conexões váliidas
		mysql_client.close()

		# Apos criar o personagem, criar o "actor_equips"
		start_equip = 0
		while start_equip < 9  do
			create_player_equips(account.account_id, actor.name, start_equip)		
			start_equip +=1
		end

		# Apos criar o personagem, criar o "actor_skills"
		actor.skills.each do |skill_id|
			create_player_skill(account.account_id, actor.name, skill_id)
		end

		# Apos criar o personagem, criar o "actor_hotbars"
		start_hotbar = 0		
		while start_hotbar < MAX_HOTBAR  do
			create_player_hotbar(account.account_id, actor.name, start_hotbar)		
			start_hotbar +=1
		end
	
		# Apos criar o personagem, criar o "actor_switches"
		start_switch = 0		
		while start_switch < MAX_PLAYER_SWITCHES  do
			create_player_swtiches(account.account_id, actor.name, start_switch)		
			start_switch +=1
		end
			
		# Apos criar o personagem, criar o "actor_variables"
		start_variable = 0	
		while start_variable < MAX_PLAYER_VARIABLES  do
			create_player_variables(account.account_id, actor.name, start_variable)		
			start_variable +=1
		end

		# Cria um novo objeto mysql client, todos as demais funções já não estão mais na memória
		mysql_client = generate_mysql_client(true)

		# Consulta para pegar o ID do usuario que acabou de ser criado
		query_actor_id = "SELECT actor_id FROM actors WHERE account_id = #{account.account_id} AND name = '#{actor.name}'"

		# Comando a ser executado
		command_actor_id = mysql_client.query(query_actor_id)		
		
		# Atribui o ID de usuario ao objeto "Actor", utilizamos essa ID em outras chamadas
		command_actor_id.each do |row|
			actor.id = row["actor_id"]
		end
		
		# Atribuir os novos dados na struct "Actor"
		actor.account_id = account.account_id
		client.actors[actor_id] = actor
	end

	def self.create_player_equips(account_id, name, slot_id)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)

		# Cria um ID de personagem vázio
		actor_id = 0

		# Consulta para listar o personagem
		query_select_actor = "SELECT * FROM actors WHERE account_id = #{account_id} AND name = '#{name}'"						
		
		# Executa a consulta
		command_load = mysql_client.query(query_select_actor)
			
		# Loop para atribuir os dados do personagem carregados na consulta
		command_load.each do |row|
			actor_id = row['actor_id']
		end
	
		# Consulta para criar um "actor_equip"
		query_create_actor_equip = "INSERT INTO actor_equips (actor_id, slot_id) VALUES (#{actor_id}, #{slot_id})"						
		
		# Executa a consulta
		command_create = mysql_client.query(query_create_actor_equip)
		
		# Fecha a conexão com o banco de dados
		mysql_client.close()
	end

	def self.create_player_items(actor_id, item_id, amount)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)
	
		# Consulta para criar um "actor_item"
		query_create_actor_item = "INSERT INTO actor_items (actor_id, item_id, item_amount) VALUES (#{actor_id}, #{item_id}, #{amount})"						
		
		# Executa a consulta
		command_create = mysql_client.query(query_create_actor_item)

		# Fecha a conexão com o banco de dados
		mysql_client.close()
	end

	def self.create_player_weapon(actor_id, weapon_id, amount)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)
	
		# Consulta para criar um "actor_weapons"
		query_create_actor_weapon = "INSERT INTO actor_weapons (actor_id, weapon_id, weapon_amount) VALUES (#{actor_id}, #{weapon_id}, #{amount})"						
		
		# Executa a consulta
		command_create = mysql_client.query(query_create_actor_weapon)
		
		# Fecha a conexão com o banco de dados
		mysql_client.close()
	end

	def self.create_player_armor(actor_id, armor_id, amount)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)
	
		# Consulta para criar um "actor_armors"
		query_create_actor_armor = "INSERT INTO actor_armors (actor_id, armor_id, armor_amount) VALUES (#{actor_id}, #{armor_id}, #{amount})"						
		
		# Executa a consulta
		command_create = mysql_client.query(query_create_actor_armor)
		
		# Fecha a conexão com o banco de dados
		mysql_client.close()
	end

	def self.create_player_skill(account_id, name, skill_id)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)

		# Cria um ID de personagem vázio
		actor_id = 0

		# Consulta para listar o personagem
		query_select_actor = "SELECT * FROM actors WHERE account_id = #{account_id} AND name = '#{name}'"						
		
		# Executa a consulta
		command_load = mysql_client.query(query_select_actor)
			
		# Loop para atribuir os dados do personagem carregados na consulta
		command_load.each do |row|
			actor_id = row['actor_id']
		end

		# Consulta para criar um "actor_skills"
		query_create_actor_skill = "INSERT INTO actor_skills (actor_id, skill_id) VALUES (#{actor_id}, #{skill_id})"						
		
		# Executa a consulta
		command_create = mysql_client.query(query_create_actor_skill)
		
		# Fecha a conexão com o banco de dados
		mysql_client.close()
	end

	def self.create_player_quest(actor_id, quest_id, state, kills)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)
	
		# Consulta para criar um "actor_quests"
		query_create_actor_quest = "INSERT INTO actor_quests (actor_id, quest_id, state, kills) VALUES (#{actor_id}, #{quest_id}, #{state}, #{kills})"						
		
		# Executa a consulta
		command_create = mysql_client.query(query_create_actor_quest)
		
		# Fecha a conexão com o banco de dados
		mysql_client.close()
	end

	def self.create_player_friend(actor_id, friend_id)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)
	
		# Consulta para criar um registro em "actor_friends"
		query_create_actor_friend  = "INSERT INTO actor_friends (actor_id, friend_id) VALUES (#{actor_id}, #{friend_id})"						
		
		# Executa a consulta
		command_create = mysql_client.query(query_create_actor_friend)

		# Fecha a conexão com o banco de dados
		mysql_client.close()
	end

	def self.create_player_hotbar(account_id, name, hotbar_id)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)

		# Cria um ID de personagem vázio
		actor_id = 0

		# Consulta para listar o personagem
		query_select_actor = "SELECT * FROM actors WHERE account_id = #{account_id} AND name = '#{name}'"						
		
		# Executa a consulta
		command_load = mysql_client.query(query_select_actor)
			
		# Loop para atribuir os dados do personagem carregados na consulta
		command_load.each do |row|
			actor_id = row['actor_id']
		end

		# Consulta para criar um "actor_hotbars"
		query_create_actor_hotbar = "INSERT INTO actor_hotbars (actor_id, hotbar_slot_id, type, item_id) VALUES (#{actor_id}, #{hotbar_id}, 0, 0)"						
		
		# Executa a consulta
		command_create = mysql_client.query(query_create_actor_hotbar)

		# Fecha a conexão com o banco de dados
		mysql_client.close()
	end

	def self.create_player_swtiches(account_id, name, switch_slot_id)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)

		# Cria um ID de personagem vázio
		actor_id = 0

		# Consulta para listar o personagem
		query_select_actor = "SELECT * FROM actors WHERE account_id = #{account_id} AND name = '#{name}'"						
		
		# Executa a consulta
		command_load = mysql_client.query(query_select_actor)
		
		# Loop para atribuir os dados do personagem carregados na consulta
		command_load.each do |row|
			actor_id = row['actor_id']
		end

		# Consulta para criar um "actor_switches"
		query_create_actor_switch = "INSERT INTO actor_switches (actor_id, switch_slot_id, switch) VALUES (#{actor_id}, #{switch_slot_id}, false)"						
		
		# Executa a consulta
		command_create = mysql_client.query(query_create_actor_switch)

		# Fecha a conexão com o banco de dados
		mysql_client.close()
	end

	def self.create_player_variables(account_id, name, variable_slot_id)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)
		
		# Cria um ID de personagem vázio
		actor_id = 0

		# Consulta para listar o personagem
		query_select_actor = "SELECT * FROM actors WHERE account_id = #{account_id} AND name = '#{name}'"						
		
		# Executa a consulta
		command_load = mysql_client.query(query_select_actor)
		
		# Loop para atribuir os dados do personagem carregados na consulta
		command_load.each do |row|
			actor_id = row['actor_id']
		end

		# Consulta para criar um "actor_variables"
		query_create_actor_variable = "INSERT INTO actor_variables (actor_id, variable_slot_id, variable_id) VALUES (#{actor_id}, #{variable_slot_id}, 0)"						
		
		# Executa a consulta
		command_create = mysql_client.query(query_create_actor_variable)

		# Fecha a conexão com o banco de dados
		mysql_client.close()
	end

	def self.load_player_equips(actor_id)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)

		# Cria um array de equipamentos vázio
		equips = []

		# Consulta para criar o "actor equips"
		query_select_actor_equip = "SELECT equip_id FROM actor_equips WHERE actor_id = #{actor_id}"
	
		# Execcuta o comando
		command_select_actor_equip = mysql_client.query(query_select_actor_equip)
		
		# Loop para atribuir os dados do "actor_equip" carregados na consulta
		command_select_actor_equip.each do |row|
			equips.push(row["equip_id"])
		end

		# Fecha a conexão com o banco de dados
		mysql_client.close()

		# Retorna o objeto "equips"
		equips
	end

	def self.load_player_items(actor_id)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)

		# Cria um array de itens vázio
		items = {}

		# Consulta para selecionar o "actor_items"
		query_select_actor_item = "SELECT item_id, item_amount FROM actor_items WHERE actor_id = #{actor_id}"
	
		# Execcuta o comando
		command_select_actor_item = mysql_client.query(query_select_actor_item)
		
		# Loop para atribuir os dados do "actor_items" carregados na consulta
		command_select_actor_item.each do |row|
			items[row["item_id"]] = row["item_amount"]
		end
		
		# Fecha a conexão com o banco de dados
		mysql_client.close()

		# Retorna o objeto "items"
		items
	end

	def self.load_player_weapons(actor_id)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)

		# Cria um array de armas vázio
		weapons = {}

		# Consulta para selecionar o "actor_weapons"
		query_select_actor_weapon = "SELECT weapon_id, weapon_amount FROM actor_weapons WHERE actor_id = #{actor_id}"
	
		# Execcuta o comando
		command_select_actor_weapon = mysql_client.query(query_select_actor_weapon)
		
		# Loop para atribuir os dados do "actor_weapons" carregados na consulta
		command_select_actor_weapon.each do |row|
			weapons[row["weapon_id"]] = row["weapon_amount"]
		end

		# Fecha a conexão com o banco de dados
		mysql_client.close()

		# Retorna o objeto "weapons"
		weapons
	end

	def self.load_player_armors(actor_id)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)

		# Cria um hash de armaduras vázio
		armors = {}

		# Consulta para selecionar o "actor_armors"
		query_select_actor_armor = "SELECT armor_id, armor_amount FROM actor_armors WHERE actor_id = #{actor_id}"
	
		# Execcuta o comando
		command_select_actor_armor = mysql_client.query(query_select_actor_armor)
		
		# Loop para atribuir os dados do "actor_armors" carregados na consulta
		command_select_actor_armor.each do |row|
			armors[row["armor_id"]] = row["armor_amount"]
		end
		
		# Fecha a conexão com o banco de dados
		mysql_client.close()

		# Retorna o objeto "armors"
		armors
	end

	def self.load_player_skills(actor_id)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)

		# Cria um array de habilidades vázio
		skills = []

		# Consulta para selecionar o "actor_skills"
		query_select_actor_skill = "SELECT skill_id FROM actor_skills WHERE actor_id = #{actor_id}"
	
		# Execcuta o comando
		command_select_actor_skill = mysql_client.query(query_select_actor_skill)
		
		# Loop para atribuir os dados do "actor_skills" carregados na consulta
		command_select_actor_skill.each do |row|
			skills.push(row["skill_id"])
		end

		# Fecha a conexão com o banco de dados
		mysql_client.close()

		# Retorna o objeto "skills"
		skills
	end

	def self.load_player_quests(actor_id)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)

		# Cria um hash de missões vázio
		quests = {}

		# Consulta para selecionar o "actor_quests"
		query_select_actor_quests = "SELECT quest_id, state, kills FROM actor_quests WHERE actor_id = #{actor_id}"
	
		# Execcuta o comando
		command_select_actor_quest = mysql_client.query(query_select_actor_quests)
		
		# Loop para atribuir os dados do "actor_quests" carregados na consulta
		command_select_actor_quest.each do |row|
			quests[row["quest_id"]] = Game_Quest.new(row["quest_id"], row["state"], row["kills"])
		end

		# Fecha a conexão com o banco de dados
		mysql_client.close()

		# Retorna o objeto "quests"
		quests
	end
	
	def self.load_player_friends(actor_id)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)

		# Cria um array de amigos vázio
		friends = []

		# Consulta para selecionar o "actor_friends"
		query_select_actor_friend = "SELECT friend_name FROM actor_friends WHERE actor_id = #{actor_id}"
	
		# Execcuta o comando
		command_select_actor_friend = mysql_client.query(query_select_actor_friend)
		
		# Loop para atribuir os dados do "actor_friends" carregados na consulta
		command_select_actor_friend.each do |row|
			friends.push(row["friend_name"])
		end

		# Fecha a conexão com o banco de dados
		mysql_client.close()

		# Retorna o objeto "friends"
		friends
	end
	
	def self.load_player_hotbars(actor_id)
		# Criia o objeto mysql client
		mysql_client = generate_mysql_client(true)

		# Cria um array de atalhos vázio
		hotbars = []

		# Consulta para selecionar o "actor_hotbar"
		query_select_actor_hotbar = "SELECT hotbar_slot_id, type, item_id FROM actor_hotbars WHERE actor_id = #{actor_id}"
	
		# Execcuta o comando
		command_select_actor_hotbar = mysql_client.query(query_select_actor_hotbar)
		
		# Loop para atribuir os dados do "actor_hotbars" carregados na consulta
		command_select_actor_hotbar.each do |row|
			hotbars.push(Hotbar.new(row["type"], row["item_id"]))
		end

		# Fecha a conexão com o banco de dados
		mysql_client.close()

		# Retorna o objeto "hotbars"
		hotbars
	end

	def self.load_player_switches(actor_id)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)

		# Cria um array de switches vázio
		switches = []

		# Consulta para selecionar o "actor_switches"
		query_select_actor_switch = "SELECT switch FROM actor_switches WHERE actor_id = #{actor_id}"
	
		# Execcuta o comando
		command_select_actor_switch = mysql_client.query(query_select_actor_switch)
		
		# Loop para atribuir os dados do "actor_switches" carregados na consulta
		command_select_actor_switch.each do |row|
			switches.push(row["switch"])
		end

		# Fecha a conexão com o banco de dados
		mysql_client.close()

		# Retorna o objeto "switches"
		switches
	end

	def self.load_player_variables(actor_id)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)

		# Cria um array de variaveis vázio
		variables = []

		# Consulta para selecionar o "actor_variiables"
		query_select_actor_variable = "SELECT variable_id FROM actor_variables WHERE actor_id = #{actor_id}"
	
		# Execcuta o comando
		command_select_actor_variable = mysql_client.query(query_select_actor_variable)
		
		# Loop para atribuir os dados do "actor_variables" carregados na consulta
		command_select_actor_variable.each do |row|
			variables.push(row["variable_id"])
		end

		# Fecha a conexão com o banco de dados
		mysql_client.close()

		# Retorna o objeto "variables"
		variables
	end

	def self.load_player_self_switches(actor_id)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)

		# Cria um hash de self switches vázioo
		self_switches = {}

		# Consulta para selecionar o "actor_self_switches"
		query_select_actor_self_switch = "SELECT switch_key_1, switch_key_2, switch_key_3, switch_value FROM actor_self_switches WHERE actor_id = #{actor_id}"
	
		# Execcuta o comando
		command_select_actor_self_switch = mysql_client.query(query_select_actor_self_switch)

		# Loop para atribuir os dados do "actor_self_switches" carregados na consulta
		command_select_actor_self_switch.each do |row|
			key = [row["switch_key_1"],  row["switch_key_2"], row["switch_key_3"]]
			self_switches[key] = row["switch_value"]
		end

		# Fecha a conexão com o banco de dados
		mysql_client.close()

		# Retorna o objeto "self_switches"
		self_switches
	end

	def self.load_player(actor_id)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)

		# Cria o objeto "Actor"
		actor = Actor.new

		# Consulta para listar os personagens que pertencem ao usuario
		query_load_actor = "SELECT * FROM actors WHERE actor_id = '#{actor_id}' AND deleted = false"
	
		# Execcuta o comando
		command_load_actor = mysql_client.query(query_load_actor)
		
		# Loop para atribuir os dados de personagem carregados na consulta
		command_load_actor.each do |row|
			actor_id = row["actor_id"]
			actor.name = row["name"]
			actor.character_name = row["character_name"]
			actor.character_index = row["character_index"]
			actor.face_name = row["face_name"]
			actor.face_index = row["face_index"]
			actor.class_id = row["class_id"]
			actor.sex = row["sex"]
			actor.level = row["level"]
			actor.exp = row["exp"]
			actor.hp = row["hp"]
			actor.mp = row["mp"]
			maxhp = row["maxhp"]
			maxmp = row["maxmp"]
			attack = row["attack"]
			defense = row["defense"]
			intelligence = row["intelligence"]
			resistence = row["resistence"]
			agility = row["agility"]
			luck = row["luck"]
			actor.param_base = [maxhp, maxmp, attack, defense, intelligence, resistence, agility, luck]			
			actor.equips = load_player_equips(actor_id)
			actor.points = row["points"]
			actor.revive_map_id = row["revive_map_id"]
			actor.revive_x = row["revive_x"]
			actor.revive_y = row["revive_y"]
			actor.map_id = row["map_id"]
			actor.x = row["x"]
			actor.y = row["y"]
			actor.direction = row["direction"]
			actor.gold = row["gold"]
			actor.items = load_player_items(actor_id)
			actor.weapons = load_player_weapons(actor_id)
			actor.armors = load_player_armors(actor_id)
			actor.skills = load_player_skills(actor_id)		
			actor.quests = load_player_quests(actor_id)
			actor.friends = load_player_friends(actor_id)
			actor.hotbar = load_player_hotbars(actor_id)
			actor.switches = load_player_switches(actor_id)
			actor.variables = load_player_variables(actor_id)
			actor.self_switches = load_player_self_switches(actor_id)	
			actor.id = row["actor_id"]	
			actor.account_id = row["account_id"]	
		end

		# Fecha a conexão com o banco de dados
		mysql_client.close()
		
		# Retorna o objeto "actor"
		actor
	end

	def self.save_player(actor)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)

		# Consulta para atualizar o personagem
		query_update_actor = "UPDATE actors SET
								name = '#{actor.name}', 
								character_name = '#{actor.character_name}', 
								character_index = #{actor.character_index}, 
								face_name = '#{actor.face_name}', 
								face_index = #{actor.face_index}, 
								class_id = #{actor.class_id}, 
								sex = #{actor.sex}, 
								level = #{actor.level}, 
								exp = #{actor.exp}, 				
								hp = #{actor.hp}, 
								mp = #{actor.mp},
								maxhp = #{actor.param_base[0]}, 
								maxmp = #{actor.param_base[1]},
								attack = #{actor.param_base[2]},
								defense = #{actor.param_base[3]},
								intelligence = #{actor.param_base[4]},
								resistence = #{actor.param_base[5]},
								agility = #{actor.param_base[6]},
								luck = #{actor.param_base[7]},
								points = #{actor.points},
								revive_map_id = #{actor.revive_map_id},
								revive_x = #{actor.revive_x}, 
								revive_y = #{actor.revive_y},
								map_id = #{actor.map_id},
								x = #{actor.x},
								y = #{actor.y},
								direction = #{actor.direction},
								gold = #{actor.gold}
							WHERE actor_id = #{actor.id} AND account_id = #{actor.account_id}"

		# Executa a consulta
		command_update = mysql_client.query(query_update_actor)

		# Fecha a conexão com o banco de dados
		mysql_client.close()

		# Atualizar equipamentos do jogador
		clear_player_equips(actor.id)
		equip_index = 0
		9.times do
			equip_id = actor.equips[equip_index]
			save_player_equips(actor.id, equip_index, equip_id)
			equip_index += 1		
		end

		# Limpa e atualiza a tabela de itens do jogador
		clear_player_items(actor.id)
		actor.items.each do |item_id, amount|
			save_player_items(actor.id, item_id, amount)
		end

		# Limpa e atualiza a tabela de armas do jogador
		clear_player_weapons(actor.id)
		actor.weapons.each do |weapon_id, amount|
			save_player_weapons(actor.id, weapon_id, amount)
		end

		# Limpa e atualiza a tabela de armaduras do jogador
		clear_player_armors(actor.id)
		actor.armors.each do |armor_id, amount|
			save_player_armors(actor.id, armor_id, amount)
		end

		# Atualizar habilidades do jogador
		actor.skills.each do |skill_id|
			save_player_skills(actor.id, skill_id)
		end

		# Atualizar quests do jogador
		actor.quests.each do |quest_id, quest|
			save_player_quests(actor.id, quest_id, quest.state, quest.kills)
		end

		# Limpa e atualiza a tabela amigos do jogador	
		clear_player_friends(actor.id)	
		actor.friends.each do |friend_name|
			save_player_friends(actor.id, friend_name)
		end

		# Limpa e atualiza a tabela atalhos do jogador	
		clear_player_hotbars(actor.id)
		hotbar_index = 0
		actor.hotbar.each do |hotbar|
			save_player_hotbars(actor.id, hotbar_index, hotbar.type, hotbar.item_id)
			hotbar_index += 1
		end
		
		# Atualizar switches do jogador	
		switch_index = 0
		actor.switches.each do |switch|
			save_player_switches(actor.id, switch_index, switch)
			switch_index += 1
		end
		
		# Atualizar variables do jogador	
		variable_index = 0
		actor.variables.each do |variable_id|
			save_player_variables(actor.id, variable_index, variable_id)
			variable_index += 1
		end

		# Atualizar self switches do jogador	
		actor.self_switches.each do |key, value|
			save_player_self_switches(actor.id, key[0], key[1],  key[2], value)
		end
	end

	def self.save_player_equips(actor_id, slot_id, equip_id)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)

		# Consulta para atualizar o equipamento do personagem
		query_update_equips = "UPDATE actor_equips SET equip_id = #{equip_id} WHERE actor_id = #{actor_id} AND slot_id = #{slot_id}"

		# Executa a consulta
		mysql_client.query(query_update_equips)

		# Fecha a conexão com o banco de dados
		mysql_client.close()
	end

	def self.save_player_items(actor_id, item_id, item_amount)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)
		
		# Consulta para criar um novo item
		query_insert_items = "INSERT INTO actor_items (actor_id, item_id, item_amount) VALUES (#{actor_id}, #{item_id}, #{item_amount})"

		# Executa o comando
		mysql_client.query(query_insert_items)		

		# Fecha a conexão com o banco de dados
		mysql_client.close()
	end

	def self.save_player_weapons(actor_id, weapon_id, weapon_amount)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)
		
		# Consulta para criar uma nova arma
		query_insert_weapons = "INSERT INTO actor_weapons (actor_id, weapon_id, weapon_amount) VALUES (#{actor_id}, #{weapon_id}, #{weapon_amount})"

		# Executa o comando
		mysql_client.query(query_insert_weapons)		

		# Fecha a conexão com o banco de dados
		mysql_client.close()
	end

	def self.save_player_armors(actor_id, armor_id, armor_amount)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)
		
		# Consulta para criar uma nova armaduura
		query_insert_armors = "INSERT INTO actor_armors (actor_id, armor_id, armor_amount) VALUES (#{actor_id}, #{armor_id}, #{armor_amount})"

		# Executa o comando
		mysql_client.query(query_insert_armors)		

		# Fecha a conexão com o banco de dados
		mysql_client.close()
	end

	def self.save_player_skills(actor_id, skill_id)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)
		
		# Consulta para checar se uma habilidade ja existe
		query_select_skill = "SELECT * FROM actor_skills WHERE skill_id = #{skill_id} AND actor_id = #{actor_id}"
		
		# Consulta para atualizar os dados de uma habilidade
		query_update_skills = "UPDATE actor_skills SET skill_id = #{skill_id} WHERE actor_id = #{actor_id} AND skill_id = #{skill_id}"

		# Consulta para criar uma nova habilidade
		query_insert_skills = "INSERT INTO actor_skills (actor_id, skill_id) VALUES (#{actor_id}, #{skill_id})"

		# Executa o comando para verificar se a habilidade existe
		command_check = mysql_client.query(query_select_skill)		
		if 0 == command_check.size
			# Nao existe, cria
			mysql_client.query(query_insert_skills)		
		else
			# Existe, atualiza
			mysql_client.query(query_update_skills)		
		end

		# Fecha a conexão com o banco de dados
		mysql_client.close()
	end

	def self.save_player_quests(actor_id, quest_id, state, kills)
		# Objeto mysql client
		mysql_client = generate_mysql_client(true)
		
		# Consulta para checar se a missão ja existe
		query_select_quest = "SELECT * FROM actor_quests WHERE quest_id = #{quest_id} AND actor_id = #{actor_id}"
		
		# Consulta para atualizar os dados da missão
		query_update_quests = "UPDATE actor_quests SET quest_id = #{quest_id}, state = #{state}, kills = #{kills} WHERE actor_id = #{actor_id} AND quest_id = #{quest_id}"

		# Consulta para criar uma nova missão
		query_insert_quests  = "INSERT INTO actor_quests (actor_id, quest_id, state, kills) VALUES (#{actor_id}, #{quest_id}, #{state}, #{kills})"

		# Executa o comando para verificar se exsite uma missão
		command_check = mysql_client.query(query_select_quest)		
		if 0 == command_check.size
			# Nao existe, cria.
			mysql_client.query(query_insert_quests)		
		else
			# Existe, atualiza.
			mysql_client.query(query_update_quests)		
		end

		# Fecha a conexão com o banco de dados
		mysql_client.close()
	end

	def self.save_player_friends(actor_id, friend_name)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)
		
		# Consulta para criar um novo amigo
		query_insert_friends = "INSERT INTO actor_friends (actor_id, friend_name) VALUES (#{actor_id}, '#{friend_name}')"

		# Executa o comando
		mysql_client.query(query_insert_friends)		
		
		# Fecha a conexão com o banco de dados
		mysql_client.close()
	end

	def self.save_player_hotbars(actor_id, hotbar_id, hotbar_type, hotbar_item_id)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)
		
		# Consulta para criar um novo atalho
		query_insert_hotbars  = "INSERT INTO actor_hotbars (actor_id, hotbar_slot_id, type, item_id) VALUES (#{actor_id}, #{hotbar_id}, #{hotbar_type}, #{hotbar_item_id})"

		# Executa o comando
		mysql_client.query(query_insert_hotbars)		

		# Fecha a conexão com o banco de dados
		mysql_client.close()
	end

	def self.save_player_switches(actor_id, switch_slot_id, switch)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)

		# Consulta para atualizar os dados de switch
		query_update_switches  = "UPDATE actor_switches SET switch = #{switch} WHERE actor_id = #{actor_id} AND switch_slot_id = #{switch_slot_id}"

		# Executa o comando para atualizar o switch
		mysql_client.query(query_update_switches)		

		# Fecha a conexão com o banco de dados
		mysql_client.close()
	end

	def self.save_player_variables(actor_id, variable_slot_id, variable_id)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)

		# Consulta para atualizar os dados de variavel
		query_update_variables  = "UPDATE actor_variables SET variable_id = #{variable_id} WHERE actor_id = #{actor_id} AND variable_slot_id = #{variable_slot_id}"

		# Executa o comando para atualizar a variavel
	    mysql_client.query(query_update_variables)		

		# Fecha a conexão com o banco de dados
		mysql_client.close()
	end

	def self.save_player_self_switches(actor_id, key_1, key_2, key_3, value)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)
		
		# Consulta para checar se o self switch ja existe
		query_select_self_switch = "SELECT * FROM actor_self_switches WHERE actor_id = #{actor_id} AND switch_key_1 = #{key_1} AND switch_key_2 = #{key_2} AND switch_key_3 = '#{key_3}'"
		
		# Consulta para atualizar os dados de self switch
		query_update_self_switches  = "UPDATE actor_self_switches SET switch_value = #{value} WHERE actor_id = #{actor_id} AND switch_key_1 = #{key_1} AND switch_key_2 = #{key_2} AND switch_key_3 = '#{key_3}'"

		# Consulta para criar um novo self switch
		query_insert_self_switches = "INSERT INTO actor_self_switches (actor_id, switch_key_1, switch_key_2, switch_key_3, switch_value) VALUES (#{actor_id}, #{key_1}, #{key_2}, '#{key_3}', #{value})"

		# Executa o comando para verificar se exsite o self switch
		command_check = mysql_client.query(query_select_self_switch)		
		if 0 == command_check.size
			# Nao existe, cria.
			mysql_client.query(query_insert_self_switches)		
		else
			# Existe, atualiza.
			mysql_client.query(query_update_self_switches)		
		end

		# Fecha a conexão com o banco de dados
		mysql_client.close()
	end

	def self.clear_player_equips(actor_id)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)
		
		# Consulta para limpar a tabela "actor_equips"
		query_update_equip = "UPDATE actor_equips SET equip_id = 0 WHERE actor_id = #{actor_id}"
		
		# Executa o comando
		mysql_client.query(query_update_equip)		

		# Fecha a conexão com o banco de dados
		mysql_client.close()
	end

	def self.clear_player_items(actor_id)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)
		
		# Consulta para limpar a tabela "actor_items"
		query_delete_item = "DELETE FROM actor_items WHERE actor_id = #{actor_id}"
		
		# Executa o comando
		mysql_client.query(query_delete_item)		

		# Fecha a conexão com o banco de dados
		mysql_client.close()
	end

	def self.clear_player_weapons(actor_id)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)
		
		# Consulta para limpar a tabela "actor_weapons"
		query_delete_weapon = "DELETE FROM actor_weapons WHERE actor_id = #{actor_id}"
		
		# Executa o comando
		mysql_client.query(query_delete_weapon)		

		# Fecha a conexão com o banco de dados
		mysql_client.close()
	end

	def self.clear_player_armors(actor_id)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)
		
		# Consulta para limpar a tabela "actor_armors"
		query_delete_armors = "DELETE FROM actor_armors WHERE actor_id = #{actor_id}"
		
		# Executa o comando
		mysql_client.query(query_delete_armors)		

		# Fecha a conexão com o banco de dados
		mysql_client.close()
	end

	def self.clear_player_friends(actor_id)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)
		
		# Consulta para limpar a tabela "actor_friends"
		query_delete_friend = "DELETE FROM actor_friends WHERE actor_id = #{actor_id}"
		
		# Executa o comando
		mysql_client.query(query_delete_friend)		

		# Fecha a conexão com o banco de dados
		mysql_client.close()
	end

	def self.clear_player_hotbars(actor_id)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)
		
		# Consulta para limpar a tabela "actor_hotbars"
		query_delete_hotbar = "DELETE FROM actor_hotbars WHERE actor_id = #{actor_id}"
		
		# Executa o comando
		mysql_client.query(query_delete_hotbar)		

		# Fecha a conexão com o banco de dados
		mysql_client.close()
	end


	def self.player_exist?(name)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)

		# Consulta para checar se o usuario existe
		query_check_player = "SELECT actor_id FROM actors WHERE name = '#{name}' AND deleted = false"

		# Executa o comando
		command_check = mysql_client.query(query_check_player)	

		if 0 == command_check.size
			return false # não existe
		else
			return true # existe
		end

		# Fecha a conexão com o banco de dados
		mysql_client.close()
	end

	def self.remove_player(name)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)

		# Consulta para desativar (deletar) um personagem
		query_delete_player = "UPDATE actors SET deleted = true WHERE name = '#{name}'"

		# Executa a consulta
		mysql_client.query(query_delete_player)	

		# Fecha a conexão com o banco de dados
		mysql_client.close()
	end

	def self.load_bank(client, account)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)
		
		# Cria um ID de banco vázio
		bank_id = 0

		# Cria o comando para listar os bancos
		query_load_bank = "SELECT bank_id, gold FROM banks WHERE account_id = #{account.account_id}"		
		
		# Executa o comando	
		command_load = mysql_client.query(query_load_bank)				
		
		# Atribui os dados do banco carregados na consulta
		command_load.each do |row|
			bank_id = row["bank_id"]
			client.bank_gold = row["gold"]
		end
		
		# Fecha a conexão com o banco de dados
		mysql_client.close()

		# Carrega todos os itens, armar e equipamentos do banco	
		client.bank_items = load_bank_items(bank_id)
		client.bank_armors = load_bank_armors(bank_id)
		client.bank_weapons = load_bank_weapons(bank_id)
	end

	def self.load_bank_items(bank_id)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)

		# Cria um hash vázio para os itens do banco
		bank_items = {}

		# Consulta para selecionar o "bank)items"
		query_select_bank_item = "SELECT item_id, item_amount FROM bank_items WHERE bank_id = #{bank_id}"
	
		# Execcuta o comando
		command_select_bank_item = mysql_client.query(query_select_bank_item)
		
		# Loop para atribuir os dados do "bank_items" carregados na consulta
		command_select_bank_item.each do |row|
			bank_items[row["item_id"]] = row["item_amount"]
		end
		
		# Fecha a conexão com o banco de dados
		mysql_client.close()

		# Retorna o objeto "bank_items"
		bank_items
	end

	def self.load_bank_armors(bank_id)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)

		# Cria um hash vázio para as armaduras do banco
		bank_armors = {}

		# Consulta para selecionar o "bank_armors"
		query_select_bank_armor = "SELECT armor_id, armor_amount FROM bank_armors WHERE bank_id = #{bank_id}"
	
		# Execcuta o comando
		command_select_bank_armor = mysql_client.query(query_select_bank_armor)
		
		# Loop para atribuir os dados do "bank_armors" carregados na consulta
		command_select_bank_armor.each do |row|
			bank_armors[row["armor_id"]] = row["armor_amount"]
		end
		
		# Fecha a conexão com o banco de dados
		mysql_client.close()

		# Retorna o objeto "bank_armors"
		bank_armors
	end

	def self.load_bank_weapons(bank_id)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)

		# Cria um hash vázio para as armas do banco
		bank_weapons = {}

		# Consulta para selecionar o "bank_weapons"
		query_select_bank_weapon = "SELECT weapon_id, weapon_amount FROM bank_weapons WHERE bank_id = #{bank_id}"
	
		# Execcuta o comando
		command_select_bank_weapon = mysql_client.query(query_select_bank_weapon)
		
		# Loop para atribuir os dados do "bank_weapons" carregados na consulta
		command_select_bank_weapon.each do |row|
			bank_weapons[row["weapon_id"]] = row["weapon_amount"]
		end
		
		# Fecha a conexão com o banco de dados
		mysql_client.close()

		# Retorna o objeto "bank_weapons"
		bank_weapons
	end

	def self.create_bank(account_id)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)

		# Consulta para criar um banco
		query_create_bank = "INSERT INTO banks (account_id, gold) VALUES (#{account_id}, 0)"
	
		# Execcuta o comando
		mysql_client.query(query_create_bank)
	
		# Fecha a conexão com o banco de dados
		mysql_client.close()
	end

	def self.save_bank(client, actor)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)
		
		# Cria uma ID de banco vázio
		bank_id = 0

		# Consulta para pegar a ID do banco
		query_select_bank = "SELECT bank_id FROM banks WHERE account_id = #{actor.account_id}"
		
		# Executa a consulta
		command_load = mysql_client.query(query_select_bank)	
		
		# Obtem "bank_id"
		command_load.each do |row|
			bank_id = row['bank_id']
		end
		
		# Consulta para atualizar os dados de "self switch"
		query_update_bank = "UPDATE banks SET gold = #{client.bank_gold} WHERE account_id = #{actor.account_id}"
		mysql_client.query(query_update_bank)		
		
		# Fecha a conexão com o banco de dados
		mysql_client.close()

		# Limpa a tabela e atualiza os itens do banco
		clear_bank_items(bank_id)
		client.bank_items.each do |item_id, amount|
			save_bank_items(bank_id, item_id, amount)
		end

		# Limpa a tabela e atualiza os weapons do banco
		clear_bank_weapons(bank_id)
		client.bank_weapons.each do |weapon_id, amount|
			save_bank_weapons(bank_id, weapon_id, amount)
		end

		# Limpa a tabela e atualiza os armors do banco
		clear_bank_armors(bank_id)
		client.bank_armors.each do |armor_id, amount|
			save_bank_armors(bank_id, armor_id, amount)
		end
	end

	def self.save_bank_items(bank_id, item_id, item_amount)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)
		
		# Consulta para criar um novo item no banco
		query_insert_items = "INSERT INTO bank_items (bank_id, item_id, item_amount) VALUES (#{bank_id}, #{item_id}, #{item_amount})"

		# Executa o comando
		mysql_client.query(query_insert_items)		

		# Fecha a conexão com o banco de dados
		mysql_client.close()

	end

	def self.save_bank_armors(bank_id, armor_id, armor_amount)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)

		# Consulta para criar uma nova armadura no banco
		query_insert_armors = "INSERT INTO bank_armors (bank_id, armor_id, armor_amount) VALUES (#{bank_id}, #{armor_id}, #{armor_amount})"

		# Executa o comando
		mysql_client.query(query_insert_armors)		

		# Fecha a conexão com o banco de dados
		mysql_client.close()

	end

	def self.save_bank_weapons(bank_id, weapon_id, weapon_amount)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)
		
		# Consulta para criar uma nova arma no banco
		query_insert_weapons = "INSERT INTO bank_weapons (bank_id, weapon_id, weapon_amount) VALUES (#{bank_id}, #{weapon_id}, #{weapon_amount})"

		# Executa o comando
		mysql_client.query(query_insert_weapons)		

		# Fecha a conexão com o banco de dados
		mysql_client.close()

	end

	def self.clear_bank_items(bank_id)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)
		
		# Consulta para limpar a tabela "bank_items"
		query_delete_item = "DELETE FROM bank_items WHERE bank_id = #{bank_id}"
		
		# Executa o comando
		mysql_client.query(query_delete_item)		

		# Fecha a conexão com o banco de dados
		mysql_client.close()
	end

	def self.clear_bank_weapons(bank_id)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)
		
		# Consulta para limpar a tabela "bank_weapons"
		query_delete_weapon = "DELETE FROM bank_weapons WHERE bank_id = #{bank_id}"
		
		# Executa o comando
		mysql_client.query(query_delete_weapon)		

		# Fecha a conexão com o banco de dados
		mysql_client.close()
	end

	def self.clear_bank_armors(bank_id)
		# Cria o objeto mysql client
		mysql_client = generate_mysql_client(true)
		
		# Consulta para limpar a tabela "bank_items"
		query_delete_armor = "DELETE FROM bank_armors WHERE bank_id = #{bank_id}"
		
		# Executa o comando
		mysql_client.query(query_delete_armor)		

		# Fecha a conexão com o banco de dados
		mysql_client.close()
	end

end
