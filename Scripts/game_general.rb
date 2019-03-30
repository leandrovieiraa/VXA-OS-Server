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

  def forbidden_name?(name)
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
	
	def admin_commands(client, message)
		index = message.index(' ')
		return unless index
		@log.add('Admin', :blue, "#{client.user} executou o comando: #{message}")
		command = message[0, index]
		data = message[index + 1, message.size]
		case command
		when '/kick'
			kick_player(client, data)
		when '/teleport'
			teleport_player(client, data)
		when '/go'
			go_to_player(client, data)
		when '/pull'
			pull_player(client, data)
		when '/item'
			give_item(client, $data_items, data)
		when '/weapon'
			give_item(client, $data_weapons, data)
		when '/armor'
			give_item(client, $data_armors, data)
		when '/banip'
			ban(client, Constants::COMMAND_IP_BANNED, data)
		when '/ban'
			ban(client, Constants::COMMAND_ACC_BANNED, data)
		when '/unban'
			unban(data)
		when '/switch'
			switch_id, value = *data.split
			change_global_switch(switch_id.to_i, value == 'true')
		when '/motd'
			change_motd(data)
		when '/mute'
			mute(client, data)
		else
			alert_message(client, Constants::ALERT_INVALID_COMMAND)
		end
	end

	def monitor_commands(client, message)
		index = message.index(' ')
		return unless index
		@log.add('Monitor', :blue, "#{client.user} executou o comando: #{message}")
		command = message[0, index]
		data = message[index + 1, message.size]
		case command
		when '/go'
			go_to_player(client, data)
		when '/pull'
			pull_player(client, data)
		when '/mute'
			mute(client, data)
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

	def teleport_player(client, data)
		# Retorna no máximo 4 campos, ainda que o nome do jogador seja composto
		data = data.split(' ', 4)
		if data.size < 4
			alert_message(client, Constants::ALERT_INVALID_COMMAND)
			return
		end
		map_id = data[0].to_i
		x = data[1].to_i
		y = data[2].to_i
		name = data[3]
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

	def give_item(client, items, data)
		data = data.split(' ', 3)
		if data.size < 3
			alert_message(client, Constants::ALERT_INVALID_COMMAND)
			return
		end
		item_id = data[0].to_i
		amount = data[1].to_i
		name = data[2]
		@clients.each do |client|
			next unless client
			if name == 'all' && client.in_game?
				client.gain_item(items[item_id], amount)
				alert_message(client, Constants::ALERT_GAIN_ITEM)
			elsif client.name.casecmp(name).zero?
				client.gain_item(items[item_id], amount)
				alert_message(client, Constants::ALERT_GAIN_ITEM)
				break
			end
		end
	end

	def ban(client, type, data)
		data = data.split(' ', 2)
		if data.size < 2
			alert_message(client, Constants::ALERT_INVALID_COMMAND)
			return
		end
		player = find_player(data[1])
		if !player || player.admin?
			alert_message(client, Constants::ALERT_INVALID_NAME)
			return
		end
		time = data[0].to_i * 86400 + Time.now.to_i
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

	def mute(client, name)
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
