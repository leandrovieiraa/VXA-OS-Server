#==============================================================================
# ** RPG::EquipItem
#------------------------------------------------------------------------------
# Autor: zh99998
#==============================================================================

class RPG::EquipItem < RPG::BaseItem
  def initialize
    super
    @price = 0
    @etype_id = 0
    @params = [0] * 8
    # VXA-OS
    @level = 0
  end

  attr_accessor :price
  attr_accessor :etype_id
  attr_accessor :params
  # VXA-OS
  attr_accessor :level
end