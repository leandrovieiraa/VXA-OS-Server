#==============================================================================
# ** Game_Map
#------------------------------------------------------------------------------
# Autor: Valentine
#==============================================================================

class Game_Map

	attr_reader   :events
	attr_reader   :drops
	attr_reader   :respawn_regions
	attr_accessor :total_players
	attr_accessor :pvp

	def initialize(id, data, width, height, tileset_id)
		@id = id
		@data = data
		@width = width
		@height = height
		@tileset_id = tileset_id
		@total_players = 0
		@pvp = false
		@events = {}
		@drops = []
		enemies_respawn_regions
	end

	def enemies_respawn_regions
		@respawn_regions = []
		@width.times do |x|
			@height.times do |y|
				@respawn_regions << Region.new(x, y) if region_id(x, y) == 1
			end
		end
	end

	def zero_players?
		@total_players == 0
	end

	def full_drops?
		@drops.size >= MAX_MAP_DROPS
	end

	def round_x_with_direction(x, d)
		x += d == Constants::DIR_RIGHT ? 1 : d == Constants::DIR_LEFT ? -1 : 0
	end

	def round_y_with_direction(y, d)
		y += d == Constants::DIR_DOWN ? 1 : d == Constants::DIR_UP ? -1 : 0
	end

	def refresh
		@events.each_value(&:refresh)
		refresh_tile_events
	end

	def refresh_tile_events
		@tile_events = @events.values.select(&:tile?)
	end

	def events_xy(x, y)
		@events.values.select { |event| event.pos?(x, y) }
	end

	def events_xy_nt(x, y)
		@events.values.select { |event| event.pos_nt?(x, y) }
	end

	def tile_events_xy(x, y)
		@tile_events.select { |event| event.pos_nt?(x, y) }
	end

	def valid?(x, y)
		x >= 0 && x < @width && y >= 0 && y < @height
	end
	
	def check_passage(x, y, bit)
		all_tiles(x, y).each do |tile_id|
			flag = $data_tilesets[@tileset_id].flags[tile_id]
			next if flag & 0x10 != 0
			return true if flag & bit == 0
			return false if flag & bit == bit
		end
		return false
	end

	def tile_id(x, y, z)
		@data[x, y, z] || 0
	end

	def layered_tiles(x, y)
		[2, 1, 0].collect { |z| tile_id(x, y, z) }
	end

	def all_tiles(x, y)
		tile_events_xy(x, y).collect { |ev| ev.tile_id } + layered_tiles(x, y)
	end

	def passable?(x, y, d)
		check_passage(x, y, (1 << (d / 2 - 1) & 0x0f))
	end

	def region_id(x, y)
		valid?(x, y) ? @data[x, y, 3] >> 8 : 0
	end

	def add_drop(item_id, kind, amount, x, y)
		@drops << Drop.new(item_id, kind, amount, x, y, Time.now + DROP_TIME)
		$server.send_add_drop(@id, item_id, kind, amount, x, y)
	end

	def remove_drop(drop_id)
		@drops.delete_at(drop_id)
		$server.send_remove_drop(@id, drop_id)
	end

	def update
		update_events
		update_drops
	end
	
	def update_events
		@events.each_value(&:update)
	end

	def update_drops
		@drops.each_index do |drop_id|
			# Se o drop anterior foi deletado e o próximo item da lista original, que tem mais itens
			#que a atual, está sendo executado embora não exista mais
			next unless @drops[drop_id] && Time.now > @drops[drop_id].time
			remove_drop(drop_id)
		end
	end

end
