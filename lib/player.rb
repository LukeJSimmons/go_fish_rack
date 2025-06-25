class Player
  attr_reader :name, :hand
  attr_accessor :api_key

  def initialize(name)
    @name = name
    @hand = []
  end

  def add_card_to_hand(card)
    hand.push(card)
  end
end
