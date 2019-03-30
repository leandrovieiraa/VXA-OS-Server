#==============================================================================
# ** Game_Trade
#------------------------------------------------------------------------------
# Autor: Valentine
#==============================================================================

module Game_Trade

  attr_reader   :trade_items
  attr_reader   :trade_weapons
  attr_reader   :trade_armors
  attr_reader   :trade_gold
  attr_accessor :trade_player_id

  def init_trade
    @trade_player_id = -1
    @trade_items = {}
    @trade_weapons = {}
    @trade_armors = {}
    @trade_gold = 0
  end

  def open_trade
    return unless $server.clients[@request.id]&.in_game?
    return unless @map_id == $server.clients[@request.id].map_id
    return if $server.clients[@request.id].in_trade? || $server.clients[@request.id].in_shop? || $server.clients[@request.id].in_bank?
    return if in_trade? || in_shop? || in_bank?
    @trade_player_id = @request.id
    $server.clients[@trade_player_id].trade_player_id = @id
    $server.send_accept_request(self, @request.type)
    $server.send_accept_request($server.clients[@trade_player_id], @request.type)
  end

  def close_trade
    return unless in_trade?
    $server.send_close_trade(self)
    $server.send_close_trade($server.clients[@trade_player_id])
    $server.clients[@trade_player_id].clear_trade_items
    clear_trade_items
  end

  def clear_trade_items
    @trade_player_id = -1
    @trade_items.clear
    @trade_weapons.clear
    @trade_armors.clear
    @trade_gold = 0
  end

  def close_trade_request
    return unless @request.type == Constants::REQUEST_FINISH_TRADE
    clear_request
  end

  def trade_item_container(kind)
    return @trade_items if kind == 1
    return @trade_weapons if kind == 2
    return @trade_armors if kind == 3
    return nil
  end

  def trade_item_number(container)
    container || 0
  end
=begin
  def has_trade_item?(item)
    trade_item_number(item) > 0
  end

  def full_trade?
    @trade_items.size + @trade_weapons.size + @trade_armors.size == MAX_TRADE_ITEMS
  end
=end
  def gain_trade_item(item_id, kind, amount)
    container = trade_item_container(kind)
    return unless container
=begin
		if amount > 0 && full_trade? && !has_trade_item?(container[item_id])
      $server.alert_message(self, Constants::ALERT_FULL_TRADE)
			return
    end
=end
    last_number = trade_item_number(container[item_id])
    new_number = last_number + amount
    container[item_id] = [[new_number, 0].max, MAX_ITEMS].min
    container.delete(item_id) if container[item_id] == 0
    $server.send_trade_item(self, @id, item_id, kind, amount)
    $server.send_trade_item($server.clients[@trade_player_id], @id, item_id, kind, amount)
  end

  def lose_trade_item(item, amount)
    gain_trade_item(item.id, kind_item(item), -amount)
  end

  def gain_trade_gold(amount)
    @trade_gold = [[@trade_gold + amount, 0].max, MAX_GOLD].min
    $server.send_trade_gold(self, @id, amount)
    $server.send_trade_gold($server.clients[@trade_player_id], @id, amount)
  end

  def finish_trade
    # Se o pedido foi aceito quando a troca já havia sido cancelada ou nunca existiu
    return unless in_trade?
    @trade_items.each do |item_id, amount|
      item = $data_items[item_id]
      lose_item(item, amount)
      $server.clients[@trade_player_id].gain_item(item, amount)
    end
    @trade_weapons.each do |weapon_id, amount|
      weapon = $data_weapons[weapon_id]
      lose_item(weapon, amount)
      $server.clients[@trade_player_id].gain_item(weapon, amount)
    end
    @trade_armors.each do |armor_id, amount|
      armor = $data_armors[armor_id]
      lose_item(armor, amount)
      $server.clients[@trade_player_id].gain_item(armor, amount)
    end
    $server.clients[@trade_player_id].trade_items.each do |item_id, amount|
      item = $data_items[item_id]
      gain_item(item, amount)
      $server.clients[@trade_player_id].lose_item(item, amount)
    end
    $server.clients[@trade_player_id].trade_weapons.each do |weapon_id, amount|
      weapon = $data_weapons[weapon_id]
      gain_item(weapon, amount)
      $server.clients[@trade_player_id].lose_item(weapon, amount)
    end
    $server.clients[@trade_player_id].trade_armors.each do |armor_id, amount|
      armor = $data_armors[armor_id]
      gain_item(armor, amount)
      $server.clients[@trade_player_id].lose_item(armor, amount)
    end
    gain_gold($server.clients[@trade_player_id].trade_gold - @trade_gold)
    $server.clients[@trade_player_id].gain_gold(@trade_gold - $server.clients[@trade_player_id].trade_gold)
    close_trade
  end

end
