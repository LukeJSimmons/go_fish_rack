require_relative 'card'

class Deck
  attr_accessor :cards

  def initialize
    @cards = build_cards
  end

  def reset
    initialize
  end

  def draw_card
    cards.pop
  end

  def count
    cards.count
  end

  private

  def build_cards
    Card::RANKS.flat_map do |rank|
      Card::SUITS.map do |suit|
        Card.new(rank, suit)
      end
    end
  end
end
