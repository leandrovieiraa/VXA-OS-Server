#==============================================================================
# ** Server
#------------------------------------------------------------------------------
# Autor: Valentine
#==============================================================================

class Server
	
	include Handle_Data, Send_Data, Game_General, Game_Data
	
	attr_reader   :clients, :parties, :party_ids_available, :maps, :switches

	def initialize
		puts('Iniciando servidor...')
		@clients = []
		@client_ids_available = []
		@client_high_id = 0
		@parties = []
		@party_ids_available = []
		@party_high_id = 0
		$data_enemies = []
		$data_actors = []
		$data_classes = []
		$data_skills = []
		$data_items = []
		$data_weapons = []
		$data_armors = []
		$data_tilesets = []
		$data_common_events = []
		$parallel_common_events = []
		@switches = Array.new(100, false)
		@log = Logger.new
		@maps = {}
		@ban_list = {}
	end
	
	def update
		update_clients
		update_maps
	end

	def update_clients
		@clients.each do |client|
			next unless client
			if client.in_game?
				client.update_game
			else
				client.update_menu
			end
		end
	end

	def update_maps
		@maps.each_value(&:update)
	end

	def connect_client(client)
		@clients[client.id] = client
		puts("Cliente #{client.id} conectado com o IP #{client.ip}!")
	end

	def disconnect_client(id)
		@clients[id] = nil
		@client_ids_available << id
		puts("Cliente #{id} desconectado!")
	end

	def find_empty_client_id
		# Remove o primeiro elemento da matriz e o retorna
		return @client_ids_available.shift unless @client_ids_available.empty?
		index = @client_high_id
		@client_high_id += 1
		index
	end

	def find_empty_party_id
		return @party_ids_available.shift unless @party_ids_available.empty?
		index = @party_high_id
		@party_high_id += 1
		index
	end

end
