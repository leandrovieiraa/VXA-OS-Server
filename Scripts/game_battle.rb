#==============================================================================
# ** Battle
#------------------------------------------------------------------------------
# Autor: Valentine
#==============================================================================

module Game_Battler

  ITEM_EFFECT_TABLE = {
    11 => :item_effect_recover_hp,
    12 => :item_effect_recover_mp,
    42 => :item_effect_grow,
    43 => :item_effect_learn_skill,
  }

  def in_front?(target)
    x = $server.maps[@map_id].round_x_with_direction(@x, @direction)
    y = $server.maps[@map_id].round_y_with_direction(@y, @direction)
    target.pos?(x, y)
  end

  def in_range?(target, range)
    distance_x_from(target.x).abs <= range && distance_y_from(target.y).abs <= range
  end

  def clear_target
    @target.id = -1
    @target.type = Constants::TARGET_NONE
  end

  def get_target
    # Verifica se o ID do alvo é maior ou igual a 0 para impedir que
    #retorne o último elemento da matriz
    @target.type == Constants::TARGET_ENEMY ? $server.maps[@map_id].events[@target.id] : @target.id >= 0 ? $server.clients[@target.id] : nil
  end

  def valid_target?(target)
    result = target.in_game? && target.map_id == @map_id
    clear_target unless result
    result
  end

  def apply_variance(damage, variance)
    amp = [damage.abs * variance / 100, 0].max.to_i
    var = rand(amp + 1) + rand(amp + 1) - amp
    damage >= 0 ? damage + var : damage - var
  end

  def make_damage_value(user, item, animation_id)
    value = item.damage.eval(user, self, nil)#@variables)
    value = apply_variance(value, item.damage.variance)
    send_attack(-value, 0, false, animation_id)
    # Reduz o HP, se o valor for positivo; aumenta, se for negativo
    self.hp -= value
  end

  def item_apply(user, item, animation_id)
    unless item.damage.none?
      make_damage_value(user, item, animation_id)
    end
    item.effects.each { |effect| item_effect_apply(user, item, effect) }
  end

  def item_effect_apply(user, item, effect)
    method_name = ITEM_EFFECT_TABLE[effect.code]
    send(method_name, user, item, effect) if method_name
  end

  def item_effect_recover_hp(user, item, effect)
    value = (mhp - effect.value1 + effect.value2) * 1.0#rec
    #value *= user.pha if item.is_a?(RPG::Item)
    value = value.to_i
    send_attack(value, 0, false, item.animation_id)
    self.hp += value
  end

  def item_effect_recover_mp(user, item, effect)
    value = (mmp * effect.value1 + effect.value2) * 1.0#rec
    #value *= user.pha if item.is_a?(RPG::Item)
    value = value.to_i
    send_attack(0, value, false, item.animation_id)
    self.mp += value
  end

  def item_effect_grow(user, item, effect)
    add_param(effect.data_id, effect.value1.to_i)
  end

  def item_effect_learn_skill(user, item, effect)
    learn_skill(effect.data_id) if self.is_a?(Game_Client)
  end

  def item_recover(item)
    item_apply(self, item, item.animation_id)
  end

  def max_passage(target)
    radians = Math.atan2(target.x - @x, target.y - @y)
    speed_x = Math.sin(radians)
    speed_y = Math.cos(radians)
    result = [target.x, target.y]
    range_x = (target.x - @x).abs
    range_y = (target.y - @y).abs
    range_x -= 1 if range_x > 0
    range_y -= 1 if range_y > 0
    x = @x
    y = @y
    while true
      # Soma valores decimais
      x += speed_x
      y += speed_y
      x2 = x.to_i
      y2 = y.to_i
      if !map_passable?(x2, y2, @direction)
        result = [x2, y2]
        break
      elsif distance_x_from(x2).abs > range_x || distance_y_from(y2).abs > range_y
        break
      end
    end
    result
  end

  def blocked_passage?(target, x, y)
    !target.pos?(x, y)
  end

  def map_passable?(x, y, d)
    $server.maps[@map_id].valid?(x, y) && $server.maps[@map_id].passable?(x, y, d)
  end

  def clear_target_players(type, map_id = @map_id)
    return if $server.maps[map_id].zero_players?
    $server.clients.each do |client|
      next unless client&.in_game? && client.map_id == map_id
      next unless client.target.id == @id && client.target.type == type
      client.change_target(-1, Constants::TARGET_NONE)
    end
  end

end

#==============================================================================
# ** Game_Client
#==============================================================================
class Game_Client < EventMachine::Connection

  EFFECT_COMMON_EVENT = 44

  def attack_normal
    @weapon_attack_time = Time.now + ATTACK_TIME
    $server.maps[@map_id].events.each_value do |event|
      # Se é um evento, inimigo morto, ou inimigo vivo fora do alcance
      next if event.dead? || !in_front?(event)
      hit_enemy(event, $data_weapons[weapon_id].animation_id, $data_skills[attack_skill_id])
      return
    end
    return unless $server.maps[@map_id].pvp
    return unless $server.maps[@map_id].total_players > 1
    $server.clients.each do |client|
      next if !client&.in_game? || client.map_id != @map_id || !in_front?(client) || client.admin?
      hit_player(client, $data_weapons[weapon_id].animation_id, $data_skills[attack_skill_id])
      break
    end
  end

  def attack_range
    @weapon_attack_time = Time.now + ATTACK_TIME
    range, item_id, mp_cost = RANGE_WEAPONS[weapon_id].drop(1)
    return if item_id > 0 && !has_item?($data_items[item_id])
    return if mp_cost && mp < mp_cost
    target = get_target
    return unless target && in_range?(target, range)
    lose_item($data_items[item_id], 1) if item_id > 0
    self.mp -= mp_cost if mp_cost
    x, y = max_passage(target)
    $server.send_add_projectile(self, x, y, target, Constants::PROJECTILE_WEAPON, weapon_id)
    return if blocked_passage?(target, x, y)
    if @target.type == Constants::TARGET_PLAYER && valid_target?(target) && $server.maps[@map_id].pvp && !target.admin?
      hit_player(target, $data_weapons[weapon_id].animation_id, $data_skills[attack_skill_id])
    elsif @target.type == Constants::TARGET_ENEMY && !target.dead?
      hit_enemy(target, $data_weapons[weapon_id].animation_id, $data_skills[attack_skill_id])
    end
  end

  def use_item(item)
    @item_attack_time = Time.now + COOLDOWN_SKILL_TIME
    # Se não tem o item ou ele não é usável
    return unless usable?(item)
    self.mp -= item.mp_cost if item.is_a?(RPG::Skill)
    consume_item(item) if item.is_a?(RPG::Item)
    item.effects.each { |effect| item_global_effect_apply(effect) }
    case item.scope
    when Constants::ITEM_SCOPE_ALL_ALLIES
      item_party_recovery(item)
    when Constants::ITEM_SCOPE_ENEMY..Constants::ITEM_SCOPE_ALLIES_KNOCKED_OUT
      item_attack_normal(item)
    when Constants::ITEM_SCOPE_USER
      item_recover(item)
    end
  end

  def consume_item(item)
    lose_item(item, 1) if item.consumable
  end

  def item_global_effect_apply(effect)
    @interpreter.setup(self, $data_common_events[effect.data_id].list) if effect.code == EFFECT_COMMON_EVENT
  end

  def item_attack_normal(item)
    target = get_target
    # Se não tem alvo, o alvo é um evento, inimigo morto, ou inimigo vivo fora do alcance
    if !target || target.dead? || !in_range?(target, item.range)
      # Usa o item que afeta apenas aliados no próprio jogador
      hit_player(self, item.animation_id, item) if item.for_friend?
      return
    end
    x, y = max_passage(target)
    $server.send_add_projectile(self, x, y, target, Constants::PROJECTILE_SKILL, item.id) if item.is_a?(RPG::Skill) && RANGE_SKILLS.has_key?(item.id)
    return if blocked_passage?(target, x, y)
    if @target.type == Constants::TARGET_PLAYER && valid_target?(target)
      hit_player(target, item.animation_id, item) if item.for_friend? || $server.maps[@map_id].pvp && !target.admin?
    elsif @target.type == Constants::TARGET_ENEMY
      hit_enemy(target, item.animation_id, item)
    end
  end

  def hit_player(client, animation_id, skill)
    change_target(client.id, Constants::TARGET_PLAYER)
    client.item_apply(self, skill, animation_id)
  end

  def hit_enemy(event, animation_id, skill)
    change_target(event.id, Constants::TARGET_ENEMY)
    event.target.id = @id
    event.item_apply(self, skill, animation_id)
  end

  def send_attack(hp_damage, mp_damage, critical, animation_id)
    $server.send_attack_player(@map_id, hp_damage, mp_damage, critical, @id, animation_id)
  end

  def kill
    lose_gold(@gold * LOSE_GOLD_RATE / 100)
    lose_exp(@exp * LOSE_EXP_RATE / 100)
    recover_all
    $server.transfer_player(self, @revive_map_id, @revive_x, @revive_y, Constants::DIR_DOWN)
    $server.alert_message(self, Constants::ALERT_PLAYER_DEAD)
  end

end

#==============================================================================
# ** Game_Enemy
#==============================================================================
module Game_Enemy

  CONDITIONS_MET_TABLE = {
    2 => :conditions_met_hp?,
    3 => :conditions_met_mp?,
    5 => :conditions_met_party_level?,
    6 => :conditions_met_switch?,
  }

  def update_enemy
    if in_battle?
      make_actions
    elsif dead? && Time.now > @respawn_time
      respawn
    end
  end

  def respawn
    @hp = mhp
    $server.send_enemy_respawn(self)
    change_position unless $server.maps[@map_id].respawn_regions.empty?
  end

  def kill
    @respawn_time = Time.now + RESPAWN_TIME
    clear_target_players(Constants::TARGET_ENEMY)
    treasure
    disable
    # Limpa o alvo após este ganhar experiência e ouro
    clear_target
  end

  def treasure
    # Amount será um número inteiro, ainda que o ouro seja 0 e em razão
    #disso o rand retorne um valor decimal 
    $server.clients[@target.id].gain_gold(rand(enemy.gold).to_i, false, true)
    if $server.clients[@target.id].in_party?
      $server.clients[@target.id].party_share_exp(enemy.exp * EXP_BONUS, @enemy_id)
    else
      $server.clients[@target.id].gain_exp(enemy.exp * EXP_BONUS)
      $server.clients[@target.id].add_kills_count(@enemy_id)
    end
    drop_items
  end

  def drop_items
    enemy.drop_items.each do |drop|
      next if drop.kind == 0 || rand * drop.denominator > 1
      break if $server.maps[@map_id].full_drops?
      $server.maps[@map_id].add_drop(drop.data_id, drop.kind, 1, @x, @y)
    end 
  end

  def disable
    $server.clients[@target.id].change_variable(enemy.disable_variable_id, $server.clients[@target.id].variables[enemy.disable_variable_id] + 1) if enemy.disable_variable_id > 0
    if enemy.disable_switch_id >= MAX_PLAYER_SWITCHES
      $server.change_global_switch(enemy.disable_switch_id, !$server.switches[enemy.disable_switch_id - MAX_PLAYER_SWITCHES])
    elsif enemy.disable_switch_id > 0
      $server.clients[@target.id].change_switch(enemy.disable_switch_id, !$server.clients[@target.id].switches[enemy.disable_switch_id])
    end
  end

  def change_position
    while true
      region_id = rand($server.maps[@map_id].respawn_regions.size)
      x = $server.maps[@map_id].respawn_regions[region_id].x
      y = $server.maps[@map_id].respawn_regions[region_id].y
      if passable?(x, y, 0)
        moveto(x, y)
        break
      end
    end
  end

  def make_actions
    return if @action_time > Time.now
    action = enemy.actions[rand(enemy.actions.size)]
    if action_valid?(action)
      @action_time = Time.now + ATTACK_TIME
      action.skill_id == attack_skill_id ? attack_normal : use_item(action.skill_id)
    end
  end

  def action_valid?(action)
    action_conditions_met?(action) && usable?($data_skills[action.skill_id])
  end

  def action_conditions_met?(action)
    method_name = CONDITIONS_MET_TABLE[action.condition_type]
    method_name ? send(method_name, action.condition_param1, action.condition_param2) : true
  end

  def conditions_met_hp?(param1, param2)
    hp_rate >= param1 && hp_rate <= param2
  end

  def conditions_met_mp?(param1, param2)
    mp_rate >= param1 && mp_rate <= param2
  end

  def conditions_met_level?(param1)
    $server.clients[@target.id].level >= param1
  end

  def conditions_met_switch?(param1)
    $server.clients[@target.id].switches[param1]
  end

  def attack_normal
    $server.clients.each do |client|
      next if !client&.in_game? || client.map_id != @map_id || !in_front?(client)
      client.item_apply(self, $data_skills[attack_skill_id], $data_skills[attack_skill_id].animation_id)
      break
    end
  end

  def use_item(item_id)
    item = $data_skills[item_id]
    self.mp -= item.mp_cost
    case item.scope
    when Constants::SKILL_SCOPE_ENEMY..Constants::SKILL_SCOPE_ALLIES_KNOCKED_OUT
      item_attack_normal(item)
    when Constants::SKILL_SCOPE_USER
      item_recover(item)
    end
  end

  def item_attack_normal(item)
    target = get_target
    # Se não tem alvo, o alvo é um evento, inimigo morto, ou inimigo vivo fora do alcance
    return if !target || !valid_target?(target) || !in_range?(target, @sight)
    x, y = max_passage(target)
    $server.send_add_projectile(self, x, y, target, Constants::PROJECTILE_SKILL, item.id) if RANGE_SKILLS.has_key?(item.id)
    target.item_apply(self, item, item.animation_id) unless blocked_passage?(target, x, y)
  end

  def send_attack(hp_damage, mp_damage, critical, animation_id)
    $server.send_attack_enemy(@map_id, hp_damage, mp_damage, critical, @id, animation_id)
  end

end
