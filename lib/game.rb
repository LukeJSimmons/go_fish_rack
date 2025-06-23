class Game
  attr_accessor :players

  def initialize
    @players = []
  end

  def add_player(player)
    players << player
  end

  def empty?

  end
end
