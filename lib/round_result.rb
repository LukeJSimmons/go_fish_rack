class RoundResult
  attr_reader :target, :request, :current_player, :matching_cards, :drawn_cards, :scored_books

  def initialize(target:, request:, current_player:, matching_cards:, drawn_cards:, scored_books:)
    @target = target
    @request = request
    @current_player = current_player
    @matching_cards = matching_cards
    @drawn_cards = drawn_cards
    @scored_books = scored_books
  end

  def player_action(recipient)
    "#{subject(recipient)} asked #{object(recipient)} for #{request}s"
  end

  def player_response(recipient)
    return "#{subject(recipient)} took #{matching_cards.count} #{request}s from #{object(recipient)}" unless matching_cards.empty?
    "Go Fish: #{object(recipient)} #{object(recipient) == 'You' ? "don't" : "didn't"} have any #{request}s"
  end

  def game_response(recipient)
    return "The deck is empty" if drawn_cards.empty? && matching_cards.empty?
    return if drawn_cards.empty?
    drawn_cards.each do |drawn_card|
      return "You drew a #{drawn_card.rank}" if recipient == current_player
      return "#{subject(recipient)} drew a card"
    end
  end

  def book_message(book, recipient)
    "#{subject(recipient)} made a book of #{book.first.rank}s"
  end

  private

  def subject(recipient)
    return "You" if recipient == current_player
    current_player.name
  end

  def object(recipient)
    return "You" if recipient == target
    target.name
  end
end
