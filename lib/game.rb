require_relative 'deck'

class Game
  attr_accessor :players, :deck, :players_needed_to_start

  def initialize
    @players = []
    @deck = Deck.new
    @players_needed_to_start = 1
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

  def players_needed
    players_needed_to_start - players.count
  end

  private

  def deal_cards
    players.each do |player|
      7.times { player.add_card_to_hand(deck.draw_card) }
    end
  end
end
