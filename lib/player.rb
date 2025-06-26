class Player
  attr_reader :name
  attr_accessor :api_key, :hand

  def initialize(name)
    @name = name
    @hand = []
  end

  def add_card_to_hand(card)
    hand.push(card)
    card
  end
end
