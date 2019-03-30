#==============================================================================
# ** RGSS3
#------------------------------------------------------------------------------
# Autor: Valentine
#==============================================================================

require './RGSS3/rpg'
require './RGSS3/audiofile'
require './RGSS3/bgm'
require './RGSS3/bgs'
require './RGSS3/me'
require './RGSS3/se'
require './RGSS3/table'
require './RGSS3/tone'
require './RGSS3/baseitem'
require './RGSS3/baseitem_feature'
require './RGSS3/usableitem'
require './RGSS3/usableitem_damage'
require './RGSS3/usableitem_effect'
require './RGSS3/item'
require './RGSS3/skill'
require './RGSS3/equipitem'
require './RGSS3/weapon'
require './RGSS3/armor'
require './RGSS3/enemy'
require './RGSS3/enemy_action' 
require './RGSS3/enemy_dropitem'
require './RGSS3/class'
require './RGSS3/learning'
require './RGSS3/actor'
require './RGSS3/map'
require './RGSS3/mapinfo'
require './RGSS3/tileset'
require './RGSS3/event'
require './RGSS3/event_page'
require './RGSS3/event_page_condition'
require './RGSS3/event_page_graphic'
require './RGSS3/eventcommand'
require './RGSS3/movecommand'
require './RGSS3/moveroute'
require './RGSS3/commonevent'
require './RGSS3/system'
require './RGSS3/system_terms'
require './RGSS3/system_vehicle'
require './RGSS3/system_testbattler'

def load_data(file_name)
	File.open("#{DATA_PATH}/#{file_name}", 'rb') { |f| Marshal.load(f) }
end
