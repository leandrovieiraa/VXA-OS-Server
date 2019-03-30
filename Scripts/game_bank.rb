#==============================================================================
# ** Game_Bank
#------------------------------------------------------------------------------
# Autor: Valentine
#==============================================================================

module Game_Bank

  attr_accessor :bank_items, :bank_weapons, :bank_armors, :bank_gold

  def init_bank
    @bank_items = {}
    @bank_weapons = {}
    @bank_armors = {}
    @bank_gold = 0
  end

  def open_bank
    return if in_trade? || in_shop? || in_bank?
    $server.send_open_bank(self)
    @in_bank = true
  end

  def close_bank
    return unless in_bank?
    $server.send_close_bank(self)
    @in_bank = false
  end

  def bank_item_container(kind)
    return @bank_items if kind == 1
    return @bank_weapons if kind == 2
    return @bank_armors if kind == 3
    return nil
  end

  def bank_item_number(container)
    container || 0
  end
=begin
  def has_bank_item?(item)
    bank_item_number(item) > 0
  end
=end
  def gain_bank_item(item_id, kind, amount)
    container = bank_item_container(kind)
    return unless container
=begin
		if amount > 0 && full_bank? && !has_bank_item?(container[item_id])
      $server.alert_message(self, Constants::ALERT_FULL_BANK)
			return
    end
=end
    last_number = bank_item_number(container[item_id])
    new_number = last_number + amount
    container[item_id] = [[new_number, 0].max, MAX_ITEMS].min
    container.delete(item_id) if container[item_id] == 0
    $server.send_bank_item(self, item_id, kind, amount)
  end

  def gain_bank_gold(amount)
    @bank_gold = [[@bank_gold + amount, 0].max, MAX_GOLD].min
    $server.send_bank_gold(self, amount)
  end

end
