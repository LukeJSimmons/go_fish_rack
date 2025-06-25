class RoundResult
  attr_reader :target, :request

  def initialize(target, request)
    @target = target
    @request = request
  end

  def player_action
    "You asked #{target} for #{request}s"
  end

  def player_response
    "Go Fish: #{target} doesn't have any #{request}s"
  end

  def game_response
    "You drew a card"
  end
end
