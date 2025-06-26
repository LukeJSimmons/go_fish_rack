class RoundResult
  attr_reader :target, :request, :current_player, :matching_cards, :drawn_card

  def initialize(target:, request:, current_player:, matching_cards:, drawn_card:)
    @target = target
    @request = request
    @current_player = current_player
    @matching_cards = matching_cards
    @drawn_card = drawn_card
  end

  def player_action(recipient)
    "#{subject(recipient)} asked #{target} for #{request}s"
  end

  def player_response(recipient)
    return "#{subject(recipient)} took #{matching_cards.count} #{request}s from #{target}" unless matching_cards.empty?
    "Go Fish: #{target} doesn't have any #{request}s"
  end

  def game_response
    return "You drew a #{drawn_card}" unless drawn_card == ""
    ""
  end

  private

  # Subject
  def subject(recipient)
    return "You" if recipient == current_player
    current_player.name
  end
end
