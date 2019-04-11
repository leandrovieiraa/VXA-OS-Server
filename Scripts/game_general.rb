#==============================================================================
# ** Game_General
#------------------------------------------------------------------------------
# Autor: Valentine
#==============================================================================

module Game_General
	
	def full_clients?
		@client_high_id == MAX_CONNECTIONS && @available_ids.empty?
	end

	def find_player(name)
		@clients.find { |client| client && client.name.casecmp(name).zero? }
	end

	def multi_accounts?(user)
		@clients.any? { |client| client && client.user.casecmp(user).zero? }
	end

	def multi_ip_online?(ip)
		@clients.any? { |client| client&.ip == ip }
	end

  def invalid_email?(email)
    email !~ /\A([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i
	end
	
  def invalid_name?(name)
    name =~ /[^A-Za-z ]/
  end

	def login_hacking_attempt?(client)
		return !client.connected? || client.logged?
	end

	def new_account_hacking_attempt?(client, user, pass, email)
		return true unless client.connected?
		return true if client.logged?
		return true if user.size < MIN_CHARACTERS || user.size > MAX_CHARACTERS
		# Se a senha não tem a quantidade mínima de caracteres, independentemente da
		#quantidade máxima de caracteres
		return true if pass.size < MIN_CHARACTERS
		return true if invalid_email?(email)
		return true if email.size > 40
		return false
	end

  def illegal_name?(name)
    FORBIDDEN_NAMES.any? { |word| name =~ /#{word}/i }
	end
	
	def requested_unavailable?(client, requested)
		return true if client.id == requested.id
		return true unless requested&.in_game?
		return true unless requested.map_id == client.map_id
		return true unless client.in_range?(requested, 10)
		return false
	end
	
	def banned?(key)
		key.downcase!
		result = @ban_list.has_key?(key)
		if result && Time.now.to_i > @ban_list[key]
			@ban_list.delete(key)
			result = false
		end
		result
	end

	def chat_filter(message)
		CHAT_FILTER.each { |word| message.sub!(/#{word}/i, '*' * word.size) }
		message
	end
	
	def admin_commands(client, command, str1, str2, str3, str4)
		#@log.add('Admin', :blue, "#{client.user} executou o comando: #{message}")
		case command
		when Constants::COMMAND_KICK
			kick_player(client, str1)
		when Constants::COMMAND_TELEPORT
			teleport_player(client, str1, str2, str3, str4)
		when Constants::COMMAND_GO
			go_to_player(client, str1)
		when Constants::COMMAND_PULL
			pull_player(client, str1)
		when Constants::COMMAND_ITEM
			give_item(client, $data_items, str1, str2, str3)
		when Constants::COMMAND_WEAPON
			give_item(client, $data_weapons, str1, str2, str3)
		when Constants::COMMAND_ARMOR
			give_item(client, $data_armors, str1, str2, str3)
		when Constants::COMMAND_BAN_IP
			ban(client, Constants::COMMAND_IP_BANNED, str1, str2)
		when Constants::COMMAND_BAN_ACC
			ban(client, Constants::COMMAND_ACC_BANNED, str1, str2)
		when Constants::COMMAND_UNBAN
			unban(str1)
		when Constants::COMMAND_SWITCH
			change_global_switch(str1.to_i, str2 == 1)
		when Constants::COMMAND_MOTD
			change_motd(str1)
		when Constants::COMMAND_MUTE
			mute_player(client, str1)
		else
			alert_message(client, Constants::ALERT_INVALID_COMMAND)
		end
	end

	def monitor_commands(client, command, str1, str2, str3, str4)
		#@log.add('Monitor', :blue, "#{client.user} executou o comando: #{message}")
		case command
		when Constants::COMMAND_GO
			go_to_player(client, str1)
		when Constants::COMMAND_PULL
			pull_player(client, str1)
		when Constants::COMMAND_MUTE
			mute_player(client, str1)
		else
			alert_message(client, Constants::ALERT_INVALID_COMMAND)
		end
	end

	def kick_player(client, name)
		player = find_player(name)
		if !player || player.admin?
			alert_message(client, Constants::ALERT_INVALID_NAME)
			return
		end
		global_message("#{player.name} foi expulso.")
		send_admin_command(player, Constants::COMMAND_KICKED)
		player.disconnect
	end

	def teleport_player(client, name, map_id, x, y)
		@clients.each do |player|
			next unless player
			if name == 'all' && player.in_game?
				transfer_player(player, map_id, x, y, player.direction)
				alert_message(player, Constants::ALERT_TELEPORTED)
			elsif player.name.casecmp(name).zero?
				transfer_player(player, map_id, x, y, player.direction)
				alert_message(player, Constants::ALERT_TELEPORTED)
				break
			end
		end
	end

	def go_to_player(client, name)
		player = find_player(name)
		unless player
			alert_message(client, Constants::ALERT_INVALID_NAME)
			return
		end
		transfer_player(client, player.map_id, player.x, player.y, client.direction)
	end

	def pull_player(player, name)
		@clients.each do |client|
			next unless client
			if name == 'all' && client.in_game? && client != player
				transfer_player(client, player.map_id, player.x, player.y, client.direction)
				alert_message(client, Constants::ALERT_PULLED)
			elsif client.name.casecmp(name).zero?
				transfer_player(client, player.map_id, player.x, player.y, client.direction)
				alert_message(client, Constants::ALERT_PULLED)
				break
			end
		end
	end

	def give_item(client, items, name, item_id, amount)
		@clients.each do |client|
			next unless client
			if name == 'all' && client.in_game?
				client.gain_item(items[item_id], amount, false, true)
			elsif client.name.casecmp(name).zero?
				client.gain_item(items[item_id], amount, false, true)
				break
			end
		end
	end

	def ban(client, type, name, days)
		player = find_player(name)
		if !player || player.admin?
			alert_message(client, Constants::ALERT_INVALID_NAME)
			return
		end
		time = days * 86400 + Time.now.to_i
		global_message("#{player.name} foi banido.")
		if type == Constants::COMMAND_ACC_BANNED
			@ban_list[player.user.downcase] = time
			send_admin_command(player, type)
			player.disconnect
		else
			@ban_list[player.ip] = time
			kick_banned_ip(player.ip)
		end
	end

	def kick_banned_ip(banned_ip)
		@clients.each do |client|
			next if client&.ip != banned_ip || client.admin?
			send_admin_command(client, Constants::COMMAND_IP_BANNED)
			client.disconnect
		end
	end

	def unban(user)
		@ban_list.delete(user)
	end

	def change_global_switch(switch_id, value)
		@switches[switch_id - MAX_PLAYER_SWITCHES] = value
		send_global_switch(switch_id, value)
		# Atualiza enemy_id dos eventos
		@maps.each_value(&:refresh)
	end

	def change_motd(motd)
		@motd = motd
		global_message(motd)
	end

	def mute_player(client, name)
		player = find_player(name)
		if !player || player.admin?
			alert_message(client, Constants::ALERT_INVALID_NAME)
			return
		end
		player.muted_time = Time.now + 30
		alert_message(player, Constants::ALERT_MUTED)
	end

	def whos_online(player)
		names = []
		@clients.each { |client| names << "#{client.name} [#{client.level}]" if client&.in_game? }
		# Envia no máximo 50 nomes para evitar spawn
		send_whos_online(player, "Há #{names.size} jogadores conectados: #{names.take(50).join(', ')}.")
	end

	def transfer_player(client, map_id, x, y, direction)
		client.close_windows
		if client.map_id == map_id
			client.change_position(map_id, x, y, direction)
			send_player_movement(client)
		else
			player_change_map(client, map_id, x, y, direction)
		end
	end

	def player_change_map(client, map_id, x, y, direction)
		old_map_id = client.map_id
		send_player_data(client, client.actor, map_id)
		client.change_position(map_id, x, y, direction)
		send_remove_player(client.id, old_map_id)
		send_transfer_player(client)
		send_map_players(client)
		send_map_events(client)
		send_map_drops(client)
		@maps[old_map_id].total_players -= 1
		@maps[map_id].total_players += 1
		client.clear_target_players(Constants::TARGET_PLAYER, old_map_id)
		client.clear_target
		client.clear_request
	end
	
end
