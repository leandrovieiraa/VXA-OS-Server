#==============================================================================
# ** Send_Data
#------------------------------------------------------------------------------
# Autor: Valentine
#==============================================================================

module Send_Data

	def send_data_to_map(map_id, data)
		@clients.each { |client| client.send_data(data) if client&.in_game? && client.map_id == map_id }
	end

	def send_data_to_all(data)
		@clients.each { |client| client.send_data(data) if client&.in_game? }
	end

	def send_data_to_party(party_id, data)
		@parties[party_id].each { |member| member.send_data(data) }
	end

	def send_login(client)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_LOGIN)

		# Fix null actors in account
		if client.actors == nil
			client.actors = {}
		end

		buffer.write_byte(client.actors.size)
		client.actors.each do |actor_id, actor|
			buffer.write_byte(actor_id)
			buffer.write_string(actor.name)
			buffer.write_string(actor.character_name)
			buffer.write_byte(actor.character_index)
			actor.equips.each { |equip| buffer.write_short(equip) }
		end		
		client.send_data(buffer.to_s)
	end

	def send_failed_login(client, type)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_FAIL_LOGIN)
		buffer.write_byte(type)
		client.send_data(buffer.to_s)
	end

	def send_new_account(client, type)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_NEW_ACCOUNT)
		buffer.write_byte(type)
		client.send_data(buffer.to_s)
	end

	def send_new_character(client, actor_id, actor)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_CHAR)
		buffer.write_byte(actor_id)
		buffer.write_string(actor.name)
		buffer.write_string(actor.character_name)
		buffer.write_byte(actor.character_index)
		actor.equips.each { |equip| buffer.write_short(equip) }
		client.send_data(buffer.to_s)
	end

	def send_failed_new_character(client)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_FAIL_NEW_CHAR)
		client.send_data(buffer.to_s)
	end

	def send_remove_character(client, actor_id)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_REMOVE_CHAR)
		buffer.write_byte(actor_id)
		client.send_data(buffer.to_s)
	end

	def send_use_character(client)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_USE_CHAR)
		buffer.write_short(client.id)
		buffer.write_byte(client.group)
		buffer.write_string(client.name)
		buffer.write_string(client.character_name)
		buffer.write_byte(client.character_index)
		buffer.write_string(client.face_name)
		buffer.write_byte(client.face_index)
		buffer.write_short(client.class_id)
		buffer.write_byte(client.sex)
		client.param_base.each { |param| buffer.write_int(param) }
		buffer.write_int(client.hp)
		buffer.write_int(client.mp)
		buffer.write_int(client.exp)
		client.equips.each { |equip| buffer.write_short(equip) }
		buffer.write_short(client.points)
		buffer.write_int(client.gold)
		buffer.write_byte(client.actor.items.size)
		client.actor.items.each do |item_id, amount|
			buffer.write_short(item_id)
			buffer.write_short(amount)
		end
		buffer.write_byte(client.actor.weapons.size)
		client.actor.weapons.each do |weapon_id, amount|
			buffer.write_short(weapon_id)
			buffer.write_short(amount)
		end
		buffer.write_byte(client.actor.armors.size)
		client.actor.armors.each do |armor_id, amount|
			buffer.write_short(armor_id)
			buffer.write_short(amount)
		end
		buffer.write_byte(client.skills.size)
		client.skills.each { |skill| buffer.write_short(skill) }
		quests = client.quests_in_progress
		buffer.write_byte(quests.size)
		quests.each_key { |quest_id| buffer.write_byte(quest_id) }
		client.hotbar.each do |hotbar|
			buffer.write_byte(hotbar.type)
			buffer.write_short(hotbar.item_id)
		end
		client.switches.each { |switch| buffer.write_boolean(switch) }
		client.variables.each { |variable| buffer.write_short(variable) }
		buffer.write_short(client.self_switches.size)
		client.self_switches.each do |key, value|
			buffer.write_short(key[0])
			buffer.write_short(key[1])
			buffer.write_string(key[2])
			buffer.write_boolean(value)
		end
		buffer.write_short(client.map_id)
		buffer.write_short(client.x)
		buffer.write_short(client.y)
		buffer.write_byte(client.direction)
		client.send_data(buffer.to_s)
	end

	def send_motd(client)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_MOTD)
		buffer.write_string(@motd)
		client.send_data(buffer.to_s)
	end

	def send_player_data(client, actor, map_id)
		return if @maps[map_id].zero_players?
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_PLAYER_DATA)
		buffer.write_short(client.id)
		buffer.write_byte(client.group)
		buffer.write_string(actor.name)
		buffer.write_string(actor.character_name)
		buffer.write_byte(actor.character_index)
		actor.equips.each { |equip| buffer.write_short(equip) }
		buffer.write_int(actor.param_base[Constants::PARAM_MAXHP])
		buffer.write_int(actor.hp)
		buffer.write_short(actor.x)
		buffer.write_short(actor.y)
		buffer.write_byte(actor.direction)
		send_data_to_map(map_id, buffer.to_s)
	end
	
	def send_map_players(player)
		return if @maps[player.map_id].zero_players?
		@clients.each do |client|
			next if !client&.in_game? || client.map_id != player.map_id || client == player
			buffer = Buffer_Writer.new
			buffer.write_byte(Constants::PACKET_PLAYER_DATA)
			buffer.write_short(client.id)
			buffer.write_byte(client.group)
			buffer.write_string(client.name)
			buffer.write_string(client.character_name)
			buffer.write_byte(client.character_index)
			client.equips.each { |equip| buffer.write_short(equip) }
			buffer.write_int(client.mhp)
			buffer.write_int(client.hp)
			buffer.write_short(client.x)
			buffer.write_short(client.y)
			buffer.write_byte(client.direction)
			player.send_data(buffer.to_s)
		end
	end

	def send_remove_player(client_id, map_id)
		return if @maps[map_id].zero_players?
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_REMOVE_PLAYER)
		buffer.write_short(client_id)
		send_data_to_map(map_id, buffer.to_s)
	end

	def send_ping(client)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_PING)
		client.send_data(buffer.to_s)
	end
	
	def send_player_movement(client)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_PLAYER_MOVE)
		buffer.write_short(client.id)
		buffer.write_short(client.x)
		buffer.write_short(client.y)
		buffer.write_byte(client.direction)
		send_data_to_map(client.map_id, buffer.to_s)
	end

	def player_message(client, message, color_id)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_CHAT_MSG)
		buffer.write_byte(color_id)
		buffer.write_string(message)
		client.send_data(buffer.to_s)
	end

	def map_message(map_id, message, player_id)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_MAP_MSG)
		buffer.write_short(player_id)
		buffer.write_string(message)
		send_data_to_map(map_id, buffer.to_s)
	end

	def global_message(message)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_CHAT_MSG)
		buffer.write_byte(Constants::CHAT_GLOBAL)
		buffer.write_string(message)
		send_data_to_all(buffer.to_s)
	end

	def party_message(client, message)
		return unless client.in_party?
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_CHAT_MSG)
		buffer.write_byte(Constants::CHAT_PARTY)
		buffer.write_string(message)
		send_data_to_party(client.party_id, buffer.to_s)
	end

	def private_message(client, message, name)
		return if client.name.casecmp(name).zero?
		player = find_player(name)
		unless player
			alert_message(client, Constants::ALERT_INVALID_NAME)
			return
		end
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_CHAT_MSG)
		buffer.write_byte(Constants::CHAT_PRIVATE)
		buffer.write_string(message)
		player.send_data(buffer.to_s)
		client.send_data(buffer.to_s)
	end

	def alert_message(client, type)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_ALERT_MSG)
		buffer.write_byte(type)
		client.send_data(buffer.to_s)
	end
	
	def send_whos_online(client, message)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_CHAT_MSG)
		buffer.write_byte(Constants::CHAT_GLOBAL)
		buffer.write_string(message)
		client.send_data(buffer.to_s)
	end

	def send_attack_player(map_id, hp_damage, mp_damage, critical, player_id, animation_id)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_ATTACK_PLAYER)
		buffer.write_short(player_id)
		buffer.write_short(hp_damage)
		buffer.write_short(mp_damage)
		buffer.write_boolean(critical)
		buffer.write_short(animation_id)
		send_data_to_map(map_id, buffer.to_s)
	end

	def send_attack_enemy(map_id, hp_damage, mp_damage, critical, event_id, animation_id)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_ATTACK_ENEMY)
		buffer.write_short(event_id)
		buffer.write_short(hp_damage)
		buffer.write_short(mp_damage)
		buffer.write_boolean(critical)
		buffer.write_short(animation_id)
		send_data_to_map(map_id, buffer.to_s)
	end

	def send_change_hotbar(client, id)
    buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_CHANGE_HOTBAR)
		buffer.write_byte(id)
    buffer.write_byte(client.hotbar[id].type)
    buffer.write_short(client.hotbar[id].item_id)
    client.send_data(buffer.to_s)
	end

	def send_target(client)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_TARGET)
		buffer.write_byte(client.target.type)
		buffer.write_short(client.target.id)
		client.send_data(buffer.to_s)
	end

	def send_enemy_respawn(event)
		return if @maps[event.map_id].zero_players?
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_ENEMY_RESPAWN)
		buffer.write_short(event.id)
		send_data_to_map(event.map_id, buffer.to_s)
	end

	def send_map_events(client)
		@maps[client.map_id].events.each do |event_id, event|
			buffer = Buffer_Writer.new
			buffer.write_byte(Constants::PACKET_EVENT_DATA)
			buffer.write_short(event_id)
			buffer.write_short(event.x)
			buffer.write_short(event.y)
			buffer.write_byte(event.direction)
			buffer.write_int(event.hp)
			client.send_data(buffer.to_s)
		end
	end

	def send_event_movement(event)
		return if @maps[event.map_id].zero_players?
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_EVENT_MOVE)
		buffer.write_short(event.id)
		buffer.write_short(event.x)
		buffer.write_short(event.y)
		buffer.write_byte(event.direction)
		send_data_to_map(event.map_id, buffer.to_s)
	end

	def send_map_drops(client)
		@maps[client.map_id].drops.each do |drop|
			buffer = Buffer_Writer.new
			buffer.write_byte(Constants::PACKET_ADD_DROP)
			buffer.write_short(drop.item_id)
			buffer.write_byte(drop.kind)
			buffer.write_short(drop.amount)
			buffer.write_short(drop.x)
			buffer.write_short(drop.y)
			client.send_data(buffer.to_s)
		end
	end

	def send_add_drop(map_id, item_id, kind, amount, x, y)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_ADD_DROP)
		buffer.write_short(item_id)
		buffer.write_byte(kind)
		buffer.write_short(amount)
		buffer.write_short(x)
		buffer.write_short(y)
		send_data_to_map(map_id, buffer.to_s)
	end

	def send_remove_drop(map_id, drop_id)
		return if @maps[map_id].zero_players?
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_REMOVE_DROP)
		buffer.write_byte(drop_id)
		send_data_to_map(map_id, buffer.to_s)
	end

	def send_add_projectile(client, finish_x, finish_y, target, projectile_type, projectile_id)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_ADD_PROJECTILE)
		buffer.write_short(client.x)
		buffer.write_short(client.y)
		buffer.write_short(finish_x)
		buffer.write_short(finish_y)
		buffer.write_short(target.x)
		buffer.write_short(target.y)
		buffer.write_byte(projectile_type)
		buffer.write_byte(projectile_id)
		send_data_to_map(client.map_id, buffer.to_s)
	end

	def send_player_vitals(client)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_PLAYER_VITALS)
		buffer.write_short(client.id)
		buffer.write_int(client.hp)
		buffer.write_int(client.mp)
		send_data_to_map(client.map_id, buffer.to_s)
	end

	def send_player_exp(client, exp)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_PLAYER_EXP)
		buffer.write_short(client.id)
		buffer.write_int(exp)
		send_data_to_map(client.map_id, buffer.to_s)
	end

	def send_player_switch(client, switch_id)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_SWITCH)
		buffer.write_short(switch_id)
		buffer.write_boolean(client.switches[switch_id])
		client.send_data(buffer.to_s)
	end

	def send_player_variable(client, variable_id)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_VARIABLE)
		buffer.write_short(variable_id)
		buffer.write_short(client.variables[variable_id])
		client.send_data(buffer.to_s)
	end

	def send_player_self_switch(client, key)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_SELF_SWITCH)
		buffer.write_short(key[0])
		buffer.write_short(key[1])
		buffer.write_string(key[2])
		buffer.write_boolean(client.self_switches[key])
		client.send_data(buffer.to_s)
	end

	def send_player_item(client, item_id, kind, amount, drop_sound)
    buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_PLAYER_ITEM)
		buffer.write_short(item_id)
		buffer.write_byte(kind)
		buffer.write_short(amount)
		buffer.write_boolean(drop_sound)
		client.send_data(buffer.to_s)
	end

	def send_player_gold(client, amount, shop_sound, popup)
    buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_PLAYER_GOLD)
		buffer.write_int(amount)
		buffer.write_boolean(shop_sound)
		buffer.write_boolean(popup)
		client.send_data(buffer.to_s)
	end

	def send_player_param(client, param_id, value)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_PLAYER_PARAM)
		buffer.write_short(client.id)
		buffer.write_byte(param_id)
		buffer.write_short(value)
		send_data_to_map(client.map_id, buffer.to_s)
	end

	def send_player_equip(client, slot_id)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_PLAYER_EQUIP)
		buffer.write_short(client.id)
		buffer.write_byte(slot_id)
		buffer.write_short(client.equips[slot_id])
		send_data_to_map(client.map_id, buffer.to_s)
	end

	def send_player_skill(client, skill_id)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_PLAYER_SKILL)
		buffer.write_short(skill_id)
		client.send_data(buffer.to_s)
	end

	def send_player_class(client, class_id)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_PLAYER_CLASS)
		buffer.write_short(class_id)
		client.send_data(buffer.to_s)
	end

	def send_player_graphic(client)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_PLAYER_GRAPHIC)
		buffer.write_short(client.id)
		buffer.write_string(client.character_name)
		buffer.write_byte(client.character_index)
		buffer.write_string(client.face_name)
		buffer.write_byte(client.face_index)
		send_data_to_map(client.map_id, buffer.to_s)
	end

	def send_player_points(client, points)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_PLAYER_POINTS)
		buffer.write_short(points)
		client.send_data(buffer.to_s)
	end

	def send_transfer_player(client)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_TRANSFER)
		buffer.write_short(client.map_id)
		buffer.write_short(client.x)
		buffer.write_short(client.y)
		buffer.write_byte(client.direction)
		client.send_data(buffer.to_s)
	end

	def send_open_friends(client)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_OPEN_FRIENDS)
		buffer.write_byte(client.friends.size)
		buffer.write_byte(client.online_friends_size)
		client.friends.each { |name| buffer.write_string(name) }
		client.send_data(buffer.to_s)
	end

	def send_add_friend(client, friend_name)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_ADD_FRIEND)
		buffer.write_string(friend_name)
		client.send_data(buffer.to_s)
	end
	
	def send_remove_friend(client, index)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_REMOVE_FRIEND)
		buffer.write_byte(index)
		client.send_data(buffer.to_s)
	end

	def send_join_party(client, player)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_JOIN_PARTY)
		buffer.write_short(player.id)
		buffer.write_string(player.name)
		buffer.write_string(player.face_name)
		buffer.write_byte(player.face_index)
		client.send_data(buffer.to_s)
	end

	def send_leave_party(client)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_LEAVE_PARTY)
		buffer.write_short(client.id)
		send_data_to_party(client.party_id, buffer.to_s)
	end

	def send_dissolve_party(client)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_DISSOLVE_PARTY)
		client.send_data(buffer.to_s)
	end

	def send_show_choices(client, event_id, index)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_SHOW_CHOICES)
		buffer.write_short(event_id)
		buffer.write_short(index)
		client.send_data(buffer.to_s)
	end

	def send_open_bank(client)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_OPEN_BANK)
		buffer.write_int(client.bank_gold)
		buffer.write_byte(client.bank_items.size)
		client.bank_items.each do |item_id, amount|
			buffer.write_short(item_id)
			buffer.write_short(amount)
		end
		buffer.write_byte(client.bank_weapons.size)
		client.bank_weapons.each do |weapon_id, amount|
			buffer.write_short(weapon_id)
			buffer.write_short(amount)
		end
		buffer.write_byte(client.bank_armors.size)
		client.bank_armors.each do |armor_id, amount|
			buffer.write_short(armor_id)
			buffer.write_short(amount)
		end
		client.send_data(buffer.to_s)
	end

	def send_bank_item(client, item_id, kind, amount)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_BANK_ITEM)
		buffer.write_short(item_id)
		buffer.write_byte(kind)
		buffer.write_short(amount)
		client.send_data(buffer.to_s)
	end

	def send_bank_gold(client, amount)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_BANK_GOLD)
		buffer.write_int(amount)
		client.send_data(buffer.to_s)
	end

	def send_close_bank(client)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_CLOSE_BANK)
		client.send_data(buffer.to_s)
	end

	def send_open_shop(client, event_id, index)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_OPEN_SHOP)
		buffer.write_short(event_id)
		buffer.write_short(index)
		client.send_data(buffer.to_s)
	end

	def send_close_shop(client)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_CLOSE_SHOP)
		client.send_data(buffer.to_s)
	end

	def send_open_teleport(client, teleport_id)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_OPEN_TELEPORT)
		buffer.write_byte(teleport_id)
		client.send_data(buffer.to_s)
	end

	def send_close_teleport(client)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_CLOSE_TELEPORT)
		client.send_data(buffer.to_s)
	end

	def send_request(client, type, player_name)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_REQUEST)
		buffer.write_byte(type)
		buffer.write_string(player_name)
		client.send_data(buffer.to_s)
	end

	def send_accept_request(client, type)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_ACCEPT_REQUEST)
		buffer.write_byte(type)
		client.send_data(buffer.to_s)
	end

	def send_trade_item(client, player_id, item_id, kind, amount)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_TRADE_ITEM)
		buffer.write_short(player_id)
		buffer.write_short(item_id)
		buffer.write_byte(kind)
		buffer.write_short(amount)
		client.send_data(buffer.to_s)
	end

	def send_trade_gold(client, player_id, amount)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_TRADE_GOLD)
		buffer.write_short(player_id)
		buffer.write_int(amount)
		client.send_data(buffer.to_s)
	end

	def send_close_trade(client)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_CLOSE_TRADE)
		client.send_data(buffer.to_s)
	end

	def send_new_quest(client, quest_id)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_NEW_QUEST)
		buffer.write_byte(quest_id)
		client.send_data(buffer.to_s)
	end

	def send_finish_quest(client, quest_id)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_FINISH_QUEST)
		buffer.write_byte(quest_id)
		client.send_data(buffer.to_s)
	end

	def send_admin_command(client, command)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_ADMIN_COMMAND)
		buffer.write_byte(command)
		client.send_data(buffer.to_s)
	end

	def send_global_switch(switch_id, value)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_SWITCH)
		buffer.write_short(switch_id)
		buffer.write_boolean(value)
		send_data_to_all(buffer.to_s)
	end

	def send_global_switches(client)
		buffer = Buffer_Writer.new
		buffer.write_byte(Constants::PACKET_NET_SWITCHES)
		@switches.each { |switch| buffer.write_boolean(switch) }
		client.send_data(buffer.to_s)
	end
	
end
