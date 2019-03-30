#==============================================================================
# ** Game_Party
#------------------------------------------------------------------------------
# Autor: Valentine
#==============================================================================

module Game_Party

  attr_accessor :party_id

	def party_share_exp(exp, enemy_id)
  	party_members = $server.parties[@party_id].select { |member| member.map_id == @map_id }
  	if party_members.size > exp
			gain_exp(exp)
			add_kills_count(enemy_id)
    	return
		end
		exp_share = exp / party_members.size + (exp * PARTY_BONUS[party_members.size] / 100)
		party_members.each do |member|
			member.gain_exp(exp_share)
			member.add_kills_count(enemy_id)
		end
  end
  
	def accept_party
		return if in_party?
		if $server.clients[@request.id].in_party?
			return if $server.parties[$server.clients[@request.id].party_id].size >= MAX_PARTY_MEMBERS
    	@party_id = $server.clients[@request.id].party_id
  	else
			create_party
		end
		$server.parties[@party_id].each do |member|
			$server.send_join_party(member, self)
			$server.send_join_party(self, member)
		end
		$server.parties[@party_id] << self
	end
	
	def create_party
		@party_id = $server.find_empty_party_id
		$server.clients[@request.id].party_id = @party_id
		$server.parties[@party_id] = [$server.clients[@request.id]]
	end

	def leave_party
		return unless in_party?
		$server.send_dissolve_party(self)
		$server.parties[@party_id].delete(self)
		if $server.parties[@party_id].size == 1
			dissolve_party($server.parties[@party_id].first)
		else
			$server.send_leave_party(self)
		end
		@party_id = -1
	end

	def dissolve_party(party_member)
		$server.parties[@party_id] = nil
		$server.party_ids_available << @party_id
		$server.send_dissolve_party(party_member)
		party_member.party_id = -1
	end

end
