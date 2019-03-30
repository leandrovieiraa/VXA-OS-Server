#==============================================================================
# ** RPG::Weapon
#------------------------------------------------------------------------------
# Autor: zh99998
#==============================================================================

class RPG::Weapon < RPG::EquipItem
  def initialize
    super
    @wtype_id = 0
    @animation_id = 0
    @features.push(RPG::BaseItem::Feature.new(31, 1, 0))
    @features.push(RPG::BaseItem::Feature.new(22, 0, 0))
    # VXA-OS
    @two_handed = false
  end

  def performance
    params[2] + params[4] + params.inject(0) { |r, v| r += v }
  end

  # VXA-OS
  def two_hands?
    @two_handed
  end

  attr_accessor :wtype_id
  attr_accessor :animation_id
  # VXA-OS
  attr_writer   :two_handed
end