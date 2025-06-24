class Game
  attr_accessor :players

  def initialize
    @players = []
  end

  def add_player(player)
    players << player
  end

  def empty?
    players.empty?
  end

  def start
    return if players.any? { |player| player.hand.count > 0 }

    deck = ['A','K']

    players.each { |player| player.add_card_to_hand(deck.pop) }
  end
end
