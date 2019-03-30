#==============================================================================
# ** Game_Character
#------------------------------------------------------------------------------
# Autor: Valentine
#==============================================================================

module Game_Character

	attr_accessor :direction

	def mhp; param(Constants::PARAM_MAXHP); end
	def mmp; param(Constants::PARAM_MAXMP); end
	def atk; param(Constants::PARAM_ATK);   end
	def def; param(Constants::PARAM_DEF);   end
	def mat; param(Constants::PARAM_MAT);   end
	def mdf; param(Constants::PARAM_MDF);   end
	def agi; param(Constants::PARAM_AGI);   end
	def luk; param(Constants::PARAM_LUK);   end

	def add_param(param_id, value)
		@param_base[param_id] += value
	end

	def param_plus(param_id)
		0
	end

	def param_min(param_id)
		return 0 if param_id == Constants::PARAM_MAXMP
		return 1
	end

	def param(param_id)
		value = @param_base[param_id] + param_plus(param_id)
		[[value, MAX_PARAMS].min, param_min(param_id)].max.to_i
	end

	def hp=(hp)
		@hp = [[hp, mhp].min, 0].max
		kill if dead?
	end

	def mp=(mp)
		@mp = [[mp, mmp].min, 0].max
	end

	def hp_rate
		@hp.to_f / mhp
	end

	def mp_rate
		mmp > 0 ? @mp.to_f / mmp : 0
	end

	def dead?
		@hp <= 0
	end

	def pos?(x, y)
		@x == x && @y == y
	end

	def pos_nt?(x, y)
		pos?(x, y) && !@through
	end

	def normal_priority?
		@priority_type == 1
	end

	def reverse_dir(d)
		10 - d
	end

	def passable?(x, y, d)
		x2 = $server.maps[@map_id].round_x_with_direction(x, d)
		y2 = $server.maps[@map_id].round_y_with_direction(y, d)
		return false unless $server.maps[@map_id].valid?(x2, y2)
		return true if @through
		return false unless $server.maps[@map_id].passable?(x2, y2, reverse_dir(d))
		return false if collide_with_characters?(x2, y2)
		return true
	end

	def collide_with_characters?(x, y)
		collide_with_events?(x, y)
	end

	def collide_with_events?(x, y)
		$server.maps[@map_id].events_xy_nt(x, y).any? do |event|
			# Ainda que a prioridade do evento que está colidindo não seja normal, não irá andar se
			#também for um evento para evitar que um fique no mesmo tile do outro
			event.normal_priority? && !event.erased? || self.is_a?(Game_Event)
		end
	end

	def collide_with_players?(x, y)
		$server.clients.any? do |client|
			client&.in_game? && client.map_id == @map_id && client.pos_nt?(x, y)
		end
	end

	def moveto(x, y)
		@x = x
		@y = y
		send_movement
	end

	def tile?
		@tile_id > 0 && @priority_type == 0
	end

	def check_event_trigger_touch_front
		x2 = $server.maps[@map_id].round_x_with_direction(@x, @direction)
		y2 = $server.maps[@map_id].round_y_with_direction(@y, @direction)
		check_event_trigger_touch(x2, y2)
	end

	def move_straight(d, turn_ok = true)
		@move_succeed = passable?(@x, @y, d)
		if @move_succeed
			@direction = d
			@x = $server.maps[@map_id].round_x_with_direction(@x, d)
			@y = $server.maps[@map_id].round_y_with_direction(@y, d)
			send_movement
		elsif turn_ok
			@direction = d
			send_movement
			check_event_trigger_touch_front
		end
	end

	def skill_learn?(skill_id)
		true
	end

	def skill_wtype_ok?(skill)
		true
	end

	def usable_item_conditions_met?(item)
		item.occasion < 3#movable?(item) && item.occasion < 3
	end

	def skill_conditions_met?(skill)
		skill_learn?(skill.id) && usable_item_conditions_met?(skill) && mp >= skill.mp_cost && skill_wtype_ok?(skill)
		#mp >= skill_mp_cost(skill) && !skill_sealed?(skill.id) && !skill_type_sealed?(skill.stype_id)
	end

	def item_conditions_met?(item)
		usable_item_conditions_met?(item) && has_item?(item)
	end

	def usable?(item)
		return skill_conditions_met?(item) if item.is_a?(RPG::Skill)
		return item_conditions_met?(item) if item.is_a?(RPG::Item)
		return false
	end

	def attack_skill_id
		1
	end

	def guard_skill_id
		2
	end

  def distance_x_from(x)
    @x - x
  end

  def distance_y_from(y)
    @y - y
  end

	def swap(character)
		new_x = character.x
		new_y = character.y
		character.moveto(@x, @y)
		moveto(new_x, new_y)
	end

end
