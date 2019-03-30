#==============================================================================
# ** Logger
#------------------------------------------------------------------------------
# Autor: Valentine
#==============================================================================

class Logger

	def initialize
		@text = {}
	end
	
	def add(type, color, text)
		day = Time.now.strftime("#{type}-%d-%b-%Y")
		@text[day] = "#{@text[day]}#{Time.now.strftime("%X: #{text}")}\n"
		puts(text.colorize(color))
	end

	def save_all
		@text.each do |day, text|
			file = File.open("Logs/#{day}.txt", 'a+')
			file.write(text)
			file.close
		end
	end
	
end
