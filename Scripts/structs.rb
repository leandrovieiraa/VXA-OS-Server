#==============================================================================
# ** Structs
#------------------------------------------------------------------------------
# Autor: Valentine
#==============================================================================

Hotbar = Struct.new(
	:type,
	:item_id
)

Target = Struct.new(
	:type,
	:id
)

Request = Struct.new(
	:type,
	:id
)

Region = Struct.new(
	:x,
	:y
)

Drop = Struct.new(
	:item_id,
	:kind,
	:amount,
	:x,
	:y,
	:time
)

Reward = Struct.new(
	:item_id,
	:item_kind,
	:item_amount,
	:exp,
	:gold
)

Account = Struct.new(
	:account_id, # Novo atributo para o MySQL Plugin
	:user, # Novo atributo para o MySQL Plugin
	:pass,
	:email,
	:group,
	:actors
)

Actor = Struct.new(
	:name,
	:character_name,
	:character_index,
	:face_name,
	:face_index,
	:class_id,
	:sex,
	:level,
	:exp,
	:hp,
	:mp,
	:param_base,
	:equips,
	:points,
	:revive_map_id,
	:revive_x,
	:revive_y,
	:map_id,
	:x,
	:y,
	:direction,
	:gold,
	:items,
	:weapons,
	:armors,
	:skills,
	:quests,
	:friends,
	:hotbar,
	:switches,
	:variables,
	:self_switches,
	:id, # Novo atributo para o MySQL Plugin
	:account_id # Novo atributo para o MySQL Plugin
)
