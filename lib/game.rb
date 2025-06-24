require_relative 'deck'

class Game
  attr_accessor :players, :deck

  def initialize
    @players = []
    @deck = Deck.new
  end

  def add_player(player)
    players << player
  end

  def empty?
    players.empty?
  end

  def start
    return if players.any? { |player| player.hand.count > 0 }

    deal_cards
  end

  private

  def deal_cards
    players.each do |player|
      7.times { player.add_card_to_hand(deck.draw_card) }
    end
  end
end
