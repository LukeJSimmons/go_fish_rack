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

  def empty?
    cards.empty?
  end

  def clear
    cards.clear
  end

  def shuffle!
    cards.shuffle!
  end

  def ==(other_deck)
    cards == other_deck.cards
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
