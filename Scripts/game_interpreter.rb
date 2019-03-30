#==============================================================================
# ** Game_Interpreter
#------------------------------------------------------------------------------
# Autor: Valentine
#==============================================================================

class Game_Interpreter

  COMMAND_TABLE = {
    102 => :show_choices,
    111 => :condition,
    121 => :change_switch,
    122 => :change_variable,
    123 => :change_self_switches,
    125 => :change_gold,
    126 => :change_item,
    127 => :change_weapon,
    128 => :change_armor,
    201 => :transfer_player,
    203 => :change_event_position,
    302 => :open_shop,
    311 => :change_hp,
    312 => :change_mp,
    314 => :recover_all,
    315 => :change_exp,
    316 => :change_level,
    317 => :change_param,
    318 => :change_skill,
    319 => :change_equip,
    321 => :change_class,
    322 => :change_graphic,
    355 => :call_script,
    411 => :exception,
  }
  
  def setup(client, list, event_id = 0)
    clear
    @client = client
    @event_id = event_id
    @list = list
    run
  end

  def clear
    @index = 0
    @branch = {}
  end

  def run
    while @list[@index] do
      execute_command
      @index += 1
    end
  end

  def execute_command
    command = @list[@index]
    @params = command.parameters
    @indent = command.indent
    method_name = COMMAND_TABLE[command.code]
    send(method_name) if method_name
  end

  def command_skip
    @index += 1 while @list[@index + 1].indent > @indent
  end

  def next_event_code
    @list[@index + 1].code
  end

  def get_character(param)
    if param < 0
      @client
    else
      $server.maps[@client.map_id].events[param > 0 ? param : @event_id]
    end
  end

  def operate_value(operation, operand_type, operand)
    value = operand_type == 0 ? operand : @client.variables[operand]
    operation == 0 ? value : -value
  end

  def show_choices
    @client.show_choices(@list[@index...@list.size], @event_id, @index)
  end
  
  def condition
    result = false
    case @params[0]
    when 0
      result = (@client.switches[@params[1]] == (@params[2] == 0)) if @params[1] < MAX_PLAYER_SWITCHES
      result = ($server.switches[@params[1] - MAX_PLAYER_SWITCHES] == (@params[2] == 0)) if @params[1] >= MAX_PLAYER_SWITCHES
    when 1
      value1 = @client.variables[@params[1]]
      value2 = @params[2] == 0 ? @params[3] : @client.variables[@params[3]]
      case @params[4]
      when 0
        result = (value1 == value2)
      when 1
        result = (value1 >= value2)
      when 2
        result = (value1 <= value2)
      when 3
        result = (value1 > value2)
      when 4
        result = (value1 < value2)
      when 5
        result = (value1 != value2)
      end
    when 2
      if @event_id > 0
        key = [@client.map_id, @event_id, @params[1]]
        result = (@client.self_switches[key] == (@params[2] == 0))
      end
    when 4
      case @params[2]
      when 1
        result = (@client.name == @params[3])
      when 2
        result = (@client.class_id == @params[3])
      when 3
        result = (@client.skill_learn?(@params[3]))
      when 4
        result = (@client.weapons.include?(@params[3]))
      when 5
        result = (@client.armors.include?(@params[3]))
      end
    when 6
      character = get_character(@params[1])
      result = (character.direction == @params[2]) if character
    when 7
      case @params[2]
      when 0
        result = (@client.gold >= @params[1])
      when 1
        result = (@client.gold <= @params[1])
      when 2
        result = (@client.gold < @params[1])
      end
    when 8
      result = @client.has_item?($data_items[@params[1]])
    when 9
      result = @client.has_item?($data_weapons[@params[1]], @params[2])
    when 10
      result = @client.has_item?($data_armors[@params[1]], @params[2])
    when 12
      result = eval(@params[1])
    end
    @branch[@indent] = result
    command_skip if !@branch[@indent]
  end

  def exception
    command_skip if @branch[@indent]
  end

  def change_switch
    value = (@params[2] == 0)
    (@params[0]..@params[1]).each do |switch_id|
      if switch_id < MAX_PLAYER_SWITCHES
        @client.change_switch(switch_id, value)
      else
        $server.change_global_switch(switch_id, value)
      end
    end
  end

  def change_variable
    value = 0
    case @params[3]
    when 0
      value = @params[4]
    when 1
      value = @client.variables[@params[4]]
    when 2
      value = @params[4] + rand(@params[5] - @params[4] + 1)
    when 3
      value = game_data_operand(@params[4], @params[5], @params[6])
    when 4
      value = eval(@params[4])
    end
    (@params[0]..@params[1]).each do |i|
      operate_variable(i, @params[2], value)
    end
  end

  def game_data_operand(type, param1, param2)
    case type
    when 0
      return @client.item_number($data_items[param1])
    when 1
      return @client.item_number($data_weapons[param1])
    when 2
      return @client.item_number($data_armors[param1])
    when 3
      case param2
      when 0
        return @client.level
      when 1
        return @client.exp
      when 2
        return @client.hp
      when 3
        return @client.mp
      when 4..11
        return @client.param(param2 - 4)
      end
    when 5
      character = get_character(param1)
      if character
        case param2
        when 0
          return character.x
        when 1
          return character.y
        when 2
          return character.direction
        end
      end
    when 7
      case param1
      when 0
        return @client.map_id
      when 2
        return @client.gold
      when 4
        #return Graphics.frame_count / Graphics.frame_rate
      when 5
        #return $game_timer.sec
      end
    end
    0
  end

  def operate_variable(variable_id, operation_type, value)
    begin
      case operation_type
      when 0
        @client.change_variable(variable_id, value)
      when 1
        @client.change_variable(variable_id, @client.variables[variable_id] + value)
      when 2
        @client.change_variable(variable_id, @client.variables[variable_id] - value)
      when 3
        @client.change_variable(variable_id, @client.variables[variable_id] * value)
      when 4
        @client.change_variable(variable_id, @client.variables[variable_id] / value)
      when 5
        @client.change_variable(variable_id, @client.variables[variable_id] % value)
      end
    rescue
      @client.change_variable(variable_id, 0)
    end
  end

  def change_self_switches
    return if @event_id == 0
    key = [@client.map_id, @event_id, @params[0]]
    @client.change_self_switches(key, @params[1] == 0)
  end

  def change_gold
    value = operate_value(@params[0], @params[1], @params[2])
    @client.gain_gold(value, false, @params[0] == 0)
  end

  def change_item
    value = operate_value(@params[1], @params[2], @params[3])
    @client.gain_item($data_items[@params[0]], value)
  end

  def change_weapon
    value = operate_value(@params[1], @params[2], @params[3])
    @client.gain_item($data_weapons[@params[0]], value)
  end

  def change_armor
    value = operate_value(@params[1], @params[2], @params[3])
    @client.gain_item($data_armors[@params[0]], value)
  end

  def transfer_player
    if @params[0] == 0
      map_id = @params[1]
      x = @params[2]
      y = @params[3]
    else
      map_id = @client.variables[@params[1]]
      x = @client.variables[@params[2]]
      y = @client.variables[@params[3]]
    end
    $server.transfer_player(@client, map_id, x, y, @params[4])
  end

  def change_event_position
    character = get_character(@params[0])
    return unless character
    character.direction = @params[4] if @params[4] > 0
    if @params[1] == 0
      character.moveto(@params[2], @params[3])
    elsif @params[1] == 1
      new_x = @client.variables[@params[2]]
      new_y = @client.variables[@params[3]]
      character.moveto(new_x, new_y)
    else
      character2 = get_character(@params[2])
      character.swap(character2) if character2
    end
  end

  def open_shop
    goods = [@params]
    last_index = @index
    while next_event_code == 605
      @index += 1
      goods << @list[@index].parameters
    end
    @client.open_shop(goods, @event_id, last_index) unless @client.in_trade? || @client.in_bank?
  end

  def change_hp
    value = operate_value(@params[2], @params[3], @params[4])
    @client.hp += value
  end

  def change_mp
    value = operate_value(@params[2], @params[3], @params[4])
    @client.mp += value
  end

  def recover_all
    @client.recover_all
  end

  def change_exp
    value = operate_value(@params[2], @params[3], @params[4])
    @client.change_exp(@client.exp + value)
  end

  def change_level
    value = operate_value(@params[2], @params[3], @params[4])
    @client.change_level(@client.level + value)
  end

  def change_param
    value = operate_value(@params[3], @params[4], @params[5])
    @client.add_param(@params[2], value)
  end

  def change_skill
    @client.learn_skill(@params[3]) if @params[2] == 0
  end

  def change_equip
    @client.change_equip(@params[1], @client.equip_object(@params[1], @params[2]))
  end

  def change_class
    @client.change_class(@params[1])
  end

  def change_graphic
    @client.set_graphic(@params[1], @params[2], @params[3], @params[4])
  end

  def call_script
    script = "#{@list[@index].parameters[0]}\n"
    while next_event_code == 655
      @index += 1
      script << "#{@list[@index].parameters[0]}\n"
    end
    eval(script)
  end

  def chat_add(message, color_id)
    $server.player_message(@client, message, color_id)
  end

  def start_quest(quest_id)
    @client.start_quest(quest_id)
  end

  def save_point(map_id, x, y)
    @client.save_point(map_id, x, y)
  end

  def open_bank
    @client.open_bank
  end

  def open_teleport(teleport_id)
    @client.open_teleport(teleport_id)
  end

end
