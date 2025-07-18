class Card
  attr_reader :rank, :suit, :value

  RANKS = %w[2 3 4 5 6 7 8 9 10 J Q K A]
  SUITS = %w[H D S C]

  def initialize(rank, suit)
    @rank = rank
    @suit = suit
    @value = RANKS.find_index(rank)
  end

  def <=>(other_card)
    RANKS.find_index(rank) <=> RANKS.find_index(other_card.rank)
  end

  def ==(other_card)
    rank == other_card.rank &&
    suit == other_card.suit
  end
end
