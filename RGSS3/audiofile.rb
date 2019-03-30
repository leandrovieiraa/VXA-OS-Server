#==============================================================================
# ** RPG::AudioFile
#------------------------------------------------------------------------------
# Autor: zh99998
#==============================================================================

class RPG::AudioFile
  def initialize(name = '', volume = 100, pitch = 100)
    @name = name
    @volume = volume
    @pitch = pitch
  end

  attr_accessor :name
  attr_accessor :volume
  attr_accessor :pitch
end