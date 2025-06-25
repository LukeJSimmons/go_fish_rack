require_relative 'deck'

class Game
  attr_accessor :players, :deck, :players_needed_to_start, :round

  def initialize
    @players = []
    @deck = Deck.new
    @players_needed_to_start = 1
    @round = 0
  end

  def add_player(player)
    players << player
  end

  def empty?
    players.empty?
  end

  def start
    deal_cards
  end

  def players_needed
    players_needed_to_start - players.count
  end

  def advance_round
    self.round += 1
  end

  def started?
    deck.count < 52
  end

  private

  def deal_cards
    players.each do |player|
      7.times { player.add_card_to_hand(deck.draw_card) }
    end
  end
end
