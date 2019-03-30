#==============================================================================
# ** Game_Quest
#------------------------------------------------------------------------------
# Autor: Valentine
#==============================================================================

class Game_Quest

  attr_reader   :switch_id
  attr_reader   :item_id
  attr_reader   :item_kind
  attr_reader   :item_amount
  attr_reader   :enemy_id
  attr_reader   :max_kills
  attr_reader   :reward
  attr_accessor :state
  attr_accessor :kills

  def initialize(id, state, kills)
    @state = state
    @kills = kills
    @switch_id = QUESTS[id][2]
    @item_id = QUESTS[id][3]
    @item_kind = QUESTS[id][4]
    @item_amount = QUESTS[id][5]
    @enemy_id = QUESTS[id][6]
    @max_kills = QUESTS[id][7]
    @reward = Reward.new
    @reward.item_id = QUESTS[id][9]
    @reward.item_kind = QUESTS[id][10]
    @reward.item_amount = QUESTS[id][11]
    @reward.exp = QUESTS[id][8]
    @reward.gold = QUESTS[id][12]
    @repeat = QUESTS[id][13]
  end

  def in_progress?
    @state == Constants::QUEST_IN_PROGRESS
  end

  def finished?
    @state == Constants::QUEST_FINISHED
  end

  def repeat?
    @repeat
  end
  
end
