#==============================================================================
# ** Game_Data
#------------------------------------------------------------------------------
# Autor: Valentine
#==============================================================================

module Game_Data

  def load_game_data
		load_enemies
		load_actors
		load_classes
		load_skills
		load_items
		load_weapons
		load_armors
		load_tilesets
		load_maps
		load_common_events
		load_system
		load_motd
		load_banlist
		load_global_switches
		puts('Servidor iniciado.')
  end
  
	def load_enemies
		puts('Carregando inimigos...')
		enemies = load_data('Enemies.rvdata2')
		# Só carrega os dados que serão usados
		(1...enemies.size).each do |enemy_id|
			$data_enemies[enemy_id] = RPG::Enemy.new
			$data_enemies[enemy_id].name = enemies[enemy_id].name
			$data_enemies[enemy_id].params = enemies[enemy_id].params
			$data_enemies[enemy_id].gold = enemies[enemy_id].gold
			$data_enemies[enemy_id].exp = enemies[enemy_id].exp
			$data_enemies[enemy_id].drop_items = enemies[enemy_id].drop_items
			$data_enemies[enemy_id].actions = enemies[enemy_id].actions
			$data_enemies[enemy_id].sight = Note.read_number('Sight', enemies[enemy_id].note)
			$data_enemies[enemy_id].disable_switch_id = Note.read_number('SwitchID', enemies[enemy_id].note)
			$data_enemies[enemy_id].disable_variable_id = Note.read_number('VariableID', enemies[enemy_id].note)
		end
	end

	def load_actors
		puts('Carregando heróis...')
		actors = load_data('Actors.rvdata2')
		(1...actors.size).each do |actor_id|
			$data_actors[actor_id] = RPG::Actor.new
			$data_actors[actor_id].initial_level = actors[actor_id].initial_level
			$data_actors[actor_id].equips = actors[actor_id].equips
		end
	end

	def load_classes
		puts('Carregando classes...')
		classes = load_data('Classes.rvdata2')
		(1...classes.size).each do |class_id|
			$data_classes[class_id] = RPG::Class.new
			$data_classes[class_id].exp_params = classes[class_id].exp_params
			$data_classes[class_id].learnings = classes[class_id].learnings
			$data_classes[class_id].params = classes[class_id].params
			$data_classes[class_id].graphics = Note.read_graphics(classes[class_id].note)
		end
	end

	def load_skills
		puts('Carregando habilidades...')
		skills = load_data('Skills.rvdata2')
		(1...skills.size).each do |skill_id|
			$data_skills[skill_id] = RPG::Skill.new
			$data_skills[skill_id].id = skill_id
			$data_skills[skill_id].scope = skills[skill_id].scope
			$data_skills[skill_id].stype_id = skills[skill_id].stype_id
			$data_skills[skill_id].mp_cost = skills[skill_id].mp_cost
			$data_skills[skill_id].damage = skills[skill_id].damage
			$data_skills[skill_id].animation_id = skills[skill_id].animation_id
			$data_skills[skill_id].effects = skills[skill_id].effects
			$data_skills[skill_id].range = Note.read_number('Range', skills[skill_id].note)
		end
	end

	def load_items
		puts('Carregando itens...')
		items = load_data('Items.rvdata2')
		(1...items.size).each do |item_id|
			$data_items[item_id] = RPG::Item.new
			$data_items[item_id].id = item_id
			$data_items[item_id].scope = items[item_id].scope
			$data_items[item_id].price = items[item_id].price
			$data_items[item_id].consumable = items[item_id].consumable
			$data_items[item_id].damage = items[item_id].damage
			$data_items[item_id].animation_id = items[item_id].animation_id
			$data_items[item_id].effects = items[item_id].effects
			$data_items[item_id].range = Note.read_number('Range', items[item_id].note)
		end
	end

	def load_weapons
		puts('Carregando armas...')
		weapons = load_data('Weapons.rvdata2')
		(1...weapons.size).each do |weapon_id|
			$data_weapons[weapon_id] = RPG::Weapon.new
			$data_weapons[weapon_id].id = weapon_id
			$data_weapons[weapon_id].etype_id = weapons[weapon_id].etype_id
			$data_weapons[weapon_id].wtype_id = weapons[weapon_id].wtype_id
			$data_weapons[weapon_id].params = weapons[weapon_id].params
			$data_weapons[weapon_id].animation_id = weapons[weapon_id].animation_id
			$data_weapons[weapon_id].price = weapons[weapon_id].price
			$data_weapons[weapon_id].level = Note.read_number('Level', weapons[weapon_id].note)
			$data_weapons[weapon_id].two_handed = Note.read_boolean('TwoHanded', weapons[weapon_id].note)
		end
	end

	def load_armors
		puts('Carregando armaduras...')
		armors = load_data('Armors.rvdata2')
		(1...armors.size).each do |armor_id|
			$data_armors[armor_id] = RPG::Armor.new
			$data_armors[armor_id].id = armor_id
			etype_id = Note.read_number('Type', armors[armor_id].note)
			$data_armors[armor_id].etype_id = etype_id > 0 ? etype_id : armors[armor_id].etype_id
			$data_armors[armor_id].atype_id = armors[armor_id].atype_id
			$data_armors[armor_id].params = armors[armor_id].params
			$data_armors[armor_id].price = armors[armor_id].price
			$data_armors[armor_id].level = Note.read_number('Level', armors[armor_id].note)
		end
	end

	def load_tilesets
		puts('Carregando tilesets...')
		tilesets = load_data('Tilesets.rvdata2')
		(1...tilesets.size).each do |tileset_id|
			$data_tilesets[tileset_id] = RPG::Tileset.new
			$data_tilesets[tileset_id].flags = tilesets[tileset_id].flags
		end
	end

	def load_maps
		puts('Carregando mapas...')
		mapinfos = load_data('MapInfos.rvdata2')
		mapinfos.each_key do |map_id|
			map = load_data(sprintf('Map%03d.rvdata2', map_id))
			@maps[map_id] = Game_Map.new(map_id, map.data, map.width, map.height, map.tileset_id)
			@maps[map_id].pvp = Note.read_boolean('PvP', map.note)
			map.events.each do |event_id, event|
				@maps[map_id].events[event_id] = Game_Event.new(event_id, event.pages)
				@maps[map_id].events[event_id].map_id = map_id
				@maps[map_id].events[event_id].x = event.x
				@maps[map_id].events[event_id].y = event.y
			end
			@maps[map_id].refresh_tile_events
		end
	end

	def load_common_events
		puts('Carregando eventos comuns...')
		common_events = load_data('CommonEvents.rvdata2')
		(1...common_events.size).each do |common_event|
			$data_common_events[common_event] = RPG::CommonEvent.new
			$data_common_events[common_event].trigger = common_events[common_event].trigger
			$data_common_events[common_event].switch_id = common_events[common_event].switch_id
			$data_common_events[common_event].list = common_events[common_event].list
			$parallel_common_events << $data_common_events[common_event] if $data_common_events[common_event].parallel?
		end
	end

	def load_system
		puts('Carregando sistema...')
		system = load_data('System.rvdata2')
		$data_system = RPG::System.new
		$data_system.start_map_id = system.start_map_id
		$data_system.start_x = system.start_x
		$data_system.start_y = system.start_y
	end

	def load_motd
		puts('Carregando mensagem do dia...')
		@motd = File.read('motd.txt')
	end

	def load_banlist
		puts('Carregando lista de contas banidas...')
		file = File.open('Data/banlist.dat', 'rb')
		@ban_list = Marshal.load(file)
		file.close
	end

	def load_global_switches
		puts('Carregando switches globais...')
		file = File.open('Data/switches.dat', 'rb')
		@switches = Marshal.load(file)
		file.close
	end
  
	def save_game_data
		puts('Salvando todos os dados...'.colorize(:green))
		save_motd
		save_banlist
		save_global_switches
		save_all_players_online
		@log.save_all
	end

	def save_motd
		file = File.open('motd.txt', 'w')
		file.write(@motd)
		file.close
	end

	def save_banlist
		file = File.open('Data/banlist.dat', 'wb')
		file.write(Marshal.dump(@ban_list))
		file.close
	end

	def save_global_switches
		file = File.open('Data/switches.dat', 'wb')
		file.write(Marshal.dump(@switches))
		file.close
	end
	
	def save_all_players_online
		@clients.each { |client| client.save_data if client&.in_game? }
	end

end
