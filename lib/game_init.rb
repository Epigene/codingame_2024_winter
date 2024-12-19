# Put the one-time game setup code that comes before `loop do` here.

width, height = gets.split.map(&:to_i)
controller = Controller.new(width: width, height: height)
