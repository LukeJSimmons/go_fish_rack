class Player
  attr_reader :name, :hand

  def initialize(name)
    @name = name
    @hand = []
  end

  def add_card_to_hand(card)
    hand.unshift(card)
  end
end
