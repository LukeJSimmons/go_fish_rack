class Player
  attr_reader :name, :api_key
  attr_accessor :hand, :books

  def initialize(name, api_key=nil)
    @name = name
    @hand = []
    @books = []
    @api_key = api_key
  end

  def add_card_to_hand(card)
    hand.push(card)
    hand.sort!
    card
  end

  def score_books_if_possible
    books = hand.group_by(&:rank).values.select { |cards| cards.count == 4 }
    books.flatten.each { |card| hand.delete(card) if books.flatten.include? card } if books
    self.books += books if books
    books
  end
end
