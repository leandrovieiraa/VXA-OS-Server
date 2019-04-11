#==============================================================================
# ** Handle_Data
#------------------------------------------------------------------------------
# Autor: Valentine
#==============================================================================

module Handle_Data

	def handle_messages(client, buffer)
		begin
			header = buffer.read_byte
			if client.in_game?
				handle_messages_game(client, header, buffer)
			else
				handle_messages_menu(client, header, buffer)
			end
		rescue => e
			client.close_connection
			@log.add('Error', :red, "Erro: #{e}")
		end
	end

	def handle_messages_menu(client, header, buffer)
		case header
		when Constants::PACKET_LOGIN
			handle_login(client, buffer)
		when Constants::PACKET_NEW_ACCOUNT
			handle_new_account(client, buffer)
		when Constants::PACKET_NEW_CHAR
			handle_new_character(client, buffer)
		when Constants::PACKET_REMOVE_CHAR
			handle_remove_character(client, buffer)
		when Constants::PACKET_USE_CHAR
			handle_use_character(client, buffer)
		else
			extension_messages_menu(client, header, buffer)
		end
	end

	def handle_messages_game(client, header, buffer)
		case header
		when Constants::PACKET_PING
			handle_ping(client)
		when Constants::PACKET_PLAYER_MOVE
			handle_player_movement(client, buffer)
		when Constants::PACKET_CHAT_MSG
			handle_chat_message(client, buffer)
		when Constants::PACKET_PLAYER_ATTACK
			handle_player_attack(client)
		when Constants::PACKET_USE_ITEM
			handle_use_item(client, buffer)
		when Constants::PACKET_USE_SKILL
			handle_use_skill(client, buffer)
		when Constants::PACKET_CHANGE_HOTBAR
			handle_change_hotbar(client, buffer)
		when Constants::PACKET_USE_HOTBAR
			handle_use_hotbar(client, buffer)
		when Constants::PACKET_TARGET
			handle_target(client, buffer)
		when Constants::PACKET_ADD_DROP
			handle_add_drop(client, buffer)
		when Constants::PACKET_REMOVE_DROP
			handle_remove_drop(client, buffer)
		when Constants::PACKET_PLAYER_PARAM
			handle_player_param(client, buffer)
		when Constants::PACKET_PLAYER_EQUIP
			handle_player_equip(client, buffer)
		when Constants::PACKET_OPEN_FRIENDS
			handle_open_friends(client)
		when Constants::PACKET_REMOVE_FRIEND
			handle_remove_friend(client, buffer)
		when Constants::PACKET_LEAVE_PARTY
			handle_leave_party(client)
		when Constants::PACKET_CHOICE
			handle_choice(client, buffer)
		when Constants::PACKET_BANK_ITEM
			handle_bank_item(client, buffer)
		when Constants::PACKET_BANK_GOLD
			handle_bank_gold(client, buffer)
		when Constants::PACKET_BUY_ITEM
			handle_buy_item(client, buffer)
		when Constants::PACKET_SELL_ITEM
			handle_sell_item(client, buffer)
		when Constants::PACKET_CHOICE_TELEPORT
			handle_choice_teleport(client, buffer)
		when Constants::PACKET_REQUEST
			handle_request(client, buffer)
		when Constants::PACKET_ACCEPT_REQUEST
			handle_accept_request(client)
		when Constants::PACKET_DECLINE_REQUEST
			handle_decline_request(client)
		when Constants::PACKET_TRADE_ITEM
			handle_trade_item(client, buffer)
		when Constants::PACKET_TRADE_GOLD
			handle_trade_gold(client, buffer)
		when Constants::PACKET_CLOSE_TRADE
			handle_close_trade(client)
		when Constants::PACKET_ADMIN_COMMAND
			handle_admin_command(client, buffer)
		else
			extension_messages_game(client, header, buffer)
		end
	end
	
	def handle_login(client, buffer)
		user = buffer.read_string
		pass = buffer.read_string
		version = buffer.read_short
		if login_hacking_attempt?(client)
			client.disconnect
			return
		elsif version != GAME_VERSION
			send_failed_login(client, Constants::LOGIN_OLD_VERSION)
			client.disconnect
			return
		elsif !Database.account_exist?(user)
			send_failed_login(client, Constants::LOGIN_INVALD_USER)
			client.disconnect
			return
		elsif banned?(user)
			send_failed_login(client, Constants::LOGIN_ACC_BANNED)
			client.disconnect
			return
		elsif multi_accounts?(user)
			send_failed_login(client, Constants::LOGIN_MULTI_ACCOUNT)
			client.disconnect
			return
		end
		account = Database.load_account(user)
		unless pass == account.pass
			send_failed_login(client, Constants::LOGIN_INVALID_PASS)
			client.disconnect
			return
		end
		client.user = user
		client.pass = account.pass
		client.email = account.email
		client.group = account.group
		client.actors = account.actors
		client.handshake = true
		Database.load_bank(client, account) # foi adicionado o objeto "account"
		send_login(client)
		puts("#{user} logou com o IP #{client.ip}.")
	end

	def handle_new_account(client, buffer)
		# Evita mais de um cadastro com o mesmo usuário
		user = buffer.read_string.strip
		pass = buffer.read_string
		email = buffer.read_string
		version = buffer.read_short
		if new_account_hacking_attempt?(client, user, pass, email)
			client.disconnect
			return
		elsif version != GAME_VERSION
			send_failed_login(client, Constants::LOGIN_OLD_VERSION)
			client.disconnect
			return
		elsif Database.account_exist?(user)
			send_new_account(client, Constants::REGISTER_ACC_EXIST)
			client.disconnect
			return
		end
		Database.create_account(user, pass, email)
		send_new_account(client, Constants::REGISTER_SUCCESSFUL)
		client.disconnect
		puts("Conta #{user} criada.")
	end

	def handle_new_character(client, buffer)
		actor_id = buffer.read_byte
		name = buffer.read_string.strip.capitalize
		character_index = buffer.read_byte
		class_id = buffer.read_short
		sex = buffer.read_byte
		params = []
		8.times { params << buffer.read_byte }
		points = buffer.read_byte
		return unless client.logged?
		return if actor_id >= MAX_CHARS
		return if client.actors.has_key?(actor_id)
		return if name.size < MIN_CHARACTERS || name.size > MAX_CHARACTERS
		#return if invalid_name?(name)
		return if illegal_name?(name) && client.standard?
		return if class_id < 1 || class_id > MAX_CLASSES
		return if sex > Constants::SEX_FEMALE
		return if character_index >= $data_classes[class_id].graphics[sex].size
		return if params.inject(:+) + points > START_POINTS
		if Database.player_exist?(name)
			send_failed_new_character(client)
			return
		end
		account = Database.load_account(client.user)
		Database.create_player(client, actor_id, name, character_index, class_id, sex, params, points, account) # foi adicionado o objeto "account"
		Database.save_account(client)
		send_new_character(client, actor_id, client.actors[actor_id])
	end

	def handle_remove_character(client, buffer)
		actor_id = buffer.read_byte
		return unless client.actors.has_key?(actor_id)
		Database.remove_player(client.actors[actor_id].name)
		client.actors.delete(actor_id)
		Database.save_account(client)
		send_remove_character(client, actor_id)
	end

	def handle_use_character(client, buffer)
		actor_id = buffer.read_byte
		return unless client.actors.has_key?(actor_id)
		# Envia os dados para os jogadores que estão no mapa, exceto para o próprio jogador
		send_player_data(client, client.actors[actor_id], client.actors[actor_id].map_id)
		@maps[client.actors[actor_id].map_id].total_players += 1
		client.join_game(actor_id)
		send_use_character(client)
		send_global_switches(client)
		send_map_players(client)
		send_map_events(client)
		send_map_drops(client)
		send_motd(client)
	end

	def handle_ping(client)
		send_ping(client)
	end

	def handle_player_movement(client, buffer)
		d = buffer.read_byte
		#return if client.moving?
		return if d < Constants::DIR_DOWN || d > Constants::DIR_UP
		#client.stop_count = Time.now + 0.200
		client.move_straight(d)
		if client.move_succeed
			client.check_touch_event
			client.close_windows
		end
	end

	def handle_chat_message(client, buffer)
		message = buffer.read_string
		talk_type = buffer.read_byte
		name = buffer.read_string
		return if message.strip.empty?
		return if client.spawning?
		return if client.muted?
		client.antispam_time = Time.now + 0.5
		if message == '/who'
			whos_online(client)
			return
		end
		message = "#{client.name}: #{chat_filter(message)}"
		case talk_type
		when Constants::CHAT_MAP
			map_message(client.map_id, message, client.id)
		when Constants::CHAT_GLOBAL
			global_message(message)
		when Constants::CHAT_PARTY
			party_message(client, message)
		when Constants::CHAT_PRIVATE
			private_message(client, message, name)
		end
	end

	def handle_player_attack(client)
		return if client.attacking?
		if RANGE_WEAPONS.has_key?(client.weapon_id)
			client.attack_range
		elsif client.has_weapon?
			client.attack_normal
		end
		client.check_event_trigger_here([0])
		client.check_event_trigger_there([0])
	end

	def handle_use_item(client, buffer)
		item_id = buffer.read_short
		return if client.using_item?
		# Usa se o item existe, o jogador o tiver e for usável
		client.use_item($data_items[item_id])
	end

	def handle_use_skill(client, buffer)
		skill_id = buffer.read_short
		return if client.using_item?
		client.use_item($data_skills[skill_id])
	end

	def handle_change_hotbar(client, buffer)
		id = buffer.read_byte
		type = buffer.read_byte
		item_id = buffer.read_short
		return if id > MAX_HOTBAR
		client.change_hotbar(id, type, item_id)
	end

	def handle_use_hotbar(client, buffer)
		id = buffer.read_byte
		return unless client.hotbar[id]
		return if client.using_item?
		item_id = client.hotbar[id].item_id
		item = client.hotbar[id].type == Constants::HOTBAR_ITEM ? $data_items[item_id] : $data_skills[item_id]
		client.use_item(item)
	end

	def handle_target(client, buffer)
		type = buffer.read_byte
		target_id = buffer.read_short
		client.change_target(target_id, type)
	end

	def handle_add_drop(client, buffer)
		item_id = buffer.read_short
		kind = buffer.read_byte
		amount = buffer.read_short
		item = client.item_object(kind, item_id)
		# Impede que o item da troca, que não é removido do inventário, seja dropado
		return if client.in_trade?
		return if @maps[client.map_id].full_drops?
		return if amount < 1 || amount > client.item_number(item)
		return if client.spawning?
		client.antispam_time = Time.now + 0.5
		client.lose_item(item, amount)
		@maps[client.map_id].add_drop(item_id, kind, amount, client.x, client.y)
	end

	def handle_remove_drop(client, buffer)
		drop_id = buffer.read_byte
		drop = @maps[client.map_id].drops[drop_id]
		return unless drop
		#return unless client.in_range?(drop, 1)
		return unless client.pos?(drop.x, drop.y)
		item = client.item_object(drop.kind, drop.item_id)
		client.gain_item(item, drop.amount, true, true)
		@maps[client.map_id].remove_drop(drop_id)
	end

	def handle_player_param(client, buffer)
		param_id = buffer.read_byte
		return if client.points == 0
		client.points -= 1
		case param_id
		when Constants::PARAM_MAXHP, Constants::PARAM_MAXMP
			client.add_param(param_id, 10)
		when Constants::PARAM_ATK..Constants::PARAM_LUK
			client.add_param(param_id, 1)
		end
	end

	def handle_player_equip(client, buffer)
		slot_id = buffer.read_byte
		item_id = buffer.read_short
		return if client.spawning?
		client.antispam_time = Time.now + 0.5
		item = client.equip_object(slot_id, item_id)
		client.change_equip(slot_id, item)
	end

	def handle_open_friends(client)
		online_friends = client.friends.select { |name| find_player(name) }
		offline_friends = client.friends - online_friends
		client.friends = online_friends + offline_friends
		client.online_friends_size = online_friends.size
		send_open_friends(client)
	end
	
	def handle_remove_friend(client, buffer)
		index = buffer.read_byte
		client.friends.delete_at(index)
		client.online_friends_size -= 1 if index <= client.online_friends_size - 1
		send_remove_friend(client, index)
	end

	def handle_leave_party(client)
		# Sai do grupo se o jogador estiver em um
		client.leave_party
	end

	def handle_choice(client, buffer)
		index = buffer.read_byte
		return unless client.choosing?
		#command = client.choices[0]
		#param = command.parameters[0][index]
		#client.interpreter.setup(client, client.choices) if param
	end
	
	def handle_bank_item(client, buffer)
		item_id = buffer.read_short
		kind = buffer.read_byte
		amount = buffer.read_short
		item = client.item_object(kind, item_id)
		container = client.bank_item_container(kind)
		return unless client.in_bank?
		return unless container
		# Se o item que está sendo adicionado não existe ou a quantidade é maior que a do inventário
		return if amount > 0 && client.item_number(item) < amount
		return if amount < 0 && client.bank_item_number(container[item_id]) < amount
		client.gain_bank_item(item_id, kind, amount)
		client.lose_item(item, amount)
	end

	def handle_bank_gold(client, buffer)
		amount = buffer.read_int
		return unless client.in_bank?
		return if amount > 0 && client.gold < amount
		return if amount < 0 && client.bank_gold < amount
		client.gain_bank_gold(amount)
		client.lose_gold(amount)
	end

	def handle_buy_item(client, buffer)
		index = buffer.read_byte
		amount = buffer.read_short
		return unless client.in_shop?
		return unless client.shop_goods[index]
		kind = client.shop_goods[index][0]
		item_id = client.shop_goods[index][1]
		item = client.item_object(kind + 1, item_id)
		price = client.shop_goods[index][2] == 0 ? item.price : client.shop_goods[index][3]
		if client.gold >= price * amount
			client.gain_item(item, amount)
			client.lose_gold(price * amount, true)
		end
	end

	def handle_sell_item(client, buffer)
		item_id = buffer.read_short
		kind = buffer.read_byte
		amount = buffer.read_short
		return unless client.in_shop?
		return if client.shop_goods[0][4]
		item = client.item_object(kind, item_id)
		if client.item_number(item) >= amount
			client.lose_item(item, amount)
			client.gain_gold(amount * item.price / 2, true)
		end
	end

	def handle_choice_teleport(client, buffer)
		index = buffer.read_byte
		return unless client.in_teleport?
		return unless TELEPORTS[client.teleport_id][index]
		return if TELEPORTS[client.teleport_id][index][3] > client.gold
		map_id, x, y, amount = TELEPORTS[client.teleport_id][index]
		transfer_player(client, map_id, x, y, Constants::DIR_DOWN)
		client.lose_gold(amount)
	end

	def handle_request(client, buffer)
		type = buffer.read_byte
		player_id = buffer.read_short
		return if client.spawning?
		client.antispam_time = Time.now + 0.5
		case type
		when Constants::REQUEST_TRADE
			return if requested_unavailable?(client, @clients[player_id])
			return if client.in_trade? || client.in_shop? || client.in_bank?
			if @clients[player_id].in_trade? || @clients[player_id].in_shop? || @clients[player_id].in_bank?
				alert_message(client, Constants::ALERT_BUSY)
				return
			end
		when Constants::REQUEST_FINISH_TRADE
			return unless client.in_trade?
			player_id = client.trade_player_id
		when Constants::REQUEST_PARTY
			return if requested_unavailable?(client, @clients[player_id])
			return if client.in_party? && @parties[client.party_id].size >= MAX_PARTY_MEMBERS
			if @clients[player_id].in_party?
				alert_message(client, Constants::ALERT_IN_PARTY)
				return
			end
		when Constants::REQUEST_FRIEND
			return if requested_unavailable?(client, @clients[player_id])
			return if client.friends.size >= MAX_FRIENDS
			return if client.friends.include?(@clients[player_id].name)
		end
		@clients[player_id].request.id = client.id
		@clients[player_id].request.type = type
		send_request(@clients[player_id], type, client.name)
	end

	def handle_accept_request(client)
		case client.request.type
		when Constants::REQUEST_TRADE
			client.open_trade
		when Constants::REQUEST_FINISH_TRADE
			client.finish_trade
		when Constants::REQUEST_PARTY
			client.accept_party
		when Constants::REQUEST_FRIEND
			client.accept_friend
		end
		client.clear_request
	end

	def handle_decline_request(client)
		case client.request.type
		when Constants::REQUEST_TRADE, Constants::REQUEST_PARTY, Constants::REQUEST_FRIEND
			alert_message(@clients[client.request.id], Constants::ALERT_REQUEST_DECLINED) if @clients[client.request.id]&.in_game?
		when Constants::REQUEST_FINISH_TRADE
			alert_message(@clients[client.request.id], Constants::ALERT_TRADE_DECLINED) if client.in_trade?
		end
		client.clear_request
	end

	def handle_trade_item(client, buffer)
		item_id = buffer.read_short
		kind = buffer.read_byte
		amount = buffer.read_short
		item = client.item_object(kind, item_id)
		container = client.trade_item_container(kind)
		return unless client.in_trade?
		return unless container
		# Se o item que está sendo adicionado não existe ou a quantidade é maior que a do inventário
		return if amount > 0 && client.item_number(item) < client.trade_item_number(container[item_id]) + amount
		return if amount < 0 && client.trade_item_number(container[item_id]) < amount
		client.gain_trade_item(item_id, kind, amount)
		client.close_trade_request
	end

	def handle_trade_gold(client, buffer)
		amount = buffer.read_int
		return unless client.in_trade?
		return if amount > 0 && client.gold < client.trade_gold + amount
		return if amount < 0 && client.trade_gold < amount
		client.gain_trade_gold(amount)
		client.close_trade_request
	end
	
	def handle_close_trade(client)
		client.close_trade
	end

	def handle_admin_command(client, buffer)
		command = buffer.read_byte
		str1 = buffer.read_string
		str2 = buffer.read_short
		str3 = buffer.read_short
		str4 = buffer.read_short
		if client.admin?
			admin_commands(client, command, str1, str2, str3, str4)
		elsif client.monitor?
			monitor_commands(client, command, str1, str2, str3, str4)
		end
	end

end
