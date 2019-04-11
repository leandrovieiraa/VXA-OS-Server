#==============================================================================
# ** Game_Account
#------------------------------------------------------------------------------
# Autor: Valentine
#==============================================================================

module Game_Account

  attr_reader   :id
	attr_reader   :ip
	attr_writer   :handshake
  attr_accessor :user
  attr_accessor :pass
  attr_accessor :email
	attr_accessor :group
	attr_accessor :actors

  def init_basic
		@id = -1
		@user = ''
		@pass = ''
		@email = ''
		@group = 0
		@actor_id = -1
		@actors = {}
		@handshake = false
		@hand_time = Time.now + AUTHENTICATION_TIME
		@ip = Socket.unpack_sockaddr_in(get_peername)[1]
  end

	def connected?
		@id >= 0
	end

	def logged?
		!@user.empty?
	end

	def in_game?
		@actor_id >= 0
	end

	def standard?
		@group == Constants::GROUP_STANDARD
	end
	
	def admin?
		@group == Constants::GROUP_ADMIN
	end

	def monitor?
		@group == Constants::GROUP_MONITOR
	end

	def actor
		@actors[@actor_id]
	end
  
	def post_init
		if $server.full_clients?
			$server.send_failed_login(self, Constants::LOGIN_SERVER_FULL)
			puts("Cliente com IP #{@ip} tentou se conectar!")
			disconnect
		elsif $server.banned?(@ip)
			$server.send_failed_login(self, Constants::LOGIN_IP_BANNED)
			puts("Cliente com IP banido #{@ip} tentou se conectar!")
			disconnect
		#elsif $server.multi_ip_online?(@ip)
			#$server.send_failed_login(self, Constants::LOGIN_MULTI_IP)
			#puts("Cliente com IP #{@ip} já em uso tentou se conectar!")
			#disconnect
		else
			@id = $server.find_empty_client_id
			$server.connect_client(self)
		end
	end

	def unbind
		leave_game if in_game?
		$server.disconnect_client(@id) if connected?
	end

	def disconnect
		# Espera 100 milissegundos para desconectar
		EventMachine::Timer.new(0.1) { close_connection }
	end

	def receive_data(data)
		buffer = Binary_Reader.new(data)
		count = 0
		while buffer.can_read? && count < 25
			$server.handle_messages(self, buffer)
			count += 1
		end
	end

	def join_game(actor_id)
		@actor_id = actor_id
		@name = actor.name
		@character_name = actor.character_name
		@character_index = actor.character_index
		@face_name = actor.face_name
		@face_index = actor.face_index
		@class_id = actor.class_id
		@sex = actor.sex
		@level = actor.level
		@exp = actor.exp
		@hp = actor.hp
		@mp = actor.mp
		@param_base = actor.param_base
		@equips = actor.equips
		@points = actor.points
		@revive_map_id = actor.revive_map_id
		@revive_x = actor.revive_x
		@revive_y = actor.revive_y
		@map_id = actor.map_id
		@x = actor.x
		@y = actor.y
		@direction = actor.direction
		@gold = actor.gold
		@items = actor.items
		@weapons = actor.weapons
		@armors = actor.armors
		@skills = actor.skills
		@quests = actor.quests
		@friends = actor.friends
		@hotbar = actor.hotbar
		@switches = actor.switches
		@variables = actor.variables
		@self_switches = actor.self_switches
		@recover_time = Time.now + RECOVER_TIME
		@weapon_attack_time = Time.now
		@item_attack_time = Time.now
		@antispam_time = Time.now
		@muted_time = Time.now
		@stop_count = Time.now
		@online_friends_size = 0
		@teleport_id = -1
		@party_id = -1
		@shop_goods = nil
		@choices = nil
		clear_target
		clear_request
	end

	def leave_game
		save_data
		# Retira da lista de clientes no jogo
		@actor_id = -1
		$server.maps[@map_id].total_players -= 1
		$server.send_remove_player(@id, @map_id)
		clear_target_players(Constants::TARGET_PLAYER)
		close_trade
		leave_party
	end

	def save_data
		actor.character_name = @character_name
		actor.character_index = @character_index
		actor.face_name = @face_name
		actor.face_index = @face_index
		actor.class_id = @class_id
		actor.level = @level
		actor.exp = @exp
		actor.hp = @hp
		actor.mp = @mp
		actor.param_base = @param_base
		actor.equips = @equips
		actor.points = @points
		actor.revive_map_id = @revive_map_id
		actor.revive_x = @revive_x
		actor.revive_y = @revive_y
		actor.map_id = @map_id
		actor.x = @x
		actor.y = @y
		actor.direction = @direction
		actor.gold = @gold
		actor.items = @items
		actor.weapons = @weapons
		actor.armors = @armors
		actor.skills = @skills
		actor.quests = @quests
		actor.friends = @friends
		actor.hotbar = @hotbar
		actor.switches = @switches
		actor.variables = @variables
		actor.self_switches = @self_switches
		Database.save_player(actor)
		Database.save_bank(self, actor) # foi adicionado o objeto "actor"
	end

	def update_menu
		close_connection if !@handshake && Time.now > @hand_time
	end

end
