require_relative 'deck'
require_relative 'round_result'

class Game
  attr_accessor :players, :deck, :players_needed_to_start, :round, :round_results

  def initialize
    @players = []
    @deck = Deck.new
    @players_needed_to_start = 2
    @round = 0
    @round_results = []
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

  def play_round(target, request)
    advance_round
    result = RoundResult.new(target, request)
    self.round_results << result
    result
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

  def advance_round
    self.round += 1
  end
end
