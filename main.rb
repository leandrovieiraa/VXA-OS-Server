#==============================================================================
# ** Main
#------------------------------------------------------------------------------
# Autor: Valentine
#==============================================================================

load './configs.ini'
load './quests.ini'

require 'eventmachine'
require 'colorize'
require 'mysql2'
require 'json'
require './RGSS3/rgss'
require './Scripts/constants'
require './Scripts/buffer'
require './Scripts/note'
require './Scripts/game_character'
require './Scripts/game_map'
require './Scripts/logger'
require './Scripts/extensions'
require './Scripts/send_data'
require './Scripts/handle_data'
require './Scripts/game_general'
require './Scripts/game_data'
require './Scripts/server'
require './Scripts/structs'
require './Scripts/database'
require './Scripts/game_battle'
require './Scripts/game_trade'
require './Scripts/game_bank'
require './Scripts/game_quest'
require './Scripts/game_account'
require './Scripts/game_party'
require './Scripts/game_client'
require './Scripts/game_interpreter'
require './Scripts/game_event'

EventMachine.run do
	Database.create_database
	Signal.trap('INT') { $server.save_game_data; EventMachine.stop  }
	Signal.trap('TERM') { $server.save_game_data; EventMachine.stop }
	$server = Server.new
	# Carrega dados, utilizando-se das informações da classe Server, após $server ser definido
	$server.load_game_data
	EventMachine.start_server('0.0.0.0', PORT, Game_Client)
	# Reduz o uso da CPU
	EventMachine::PeriodicTimer.new(0.02) { $server.update }
	EventMachine::PeriodicTimer.new(SAVE_DATA_TIME) { $server.save_game_data }
end
