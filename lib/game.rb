require_relative 'deck'
require_relative 'round_result'

class Game
  attr_accessor :players, :deck, :players_needed_to_start, :round, :round_results, :ignore_books

  BASE_DECK_SIZE = 52
  BASE_HAND_SIZE = 7

  def initialize
    @players = []
    @deck = Deck.new
    @players_needed_to_start = 2
    @round = 0
    @round_results = []
  end

  def add_player(player)
    players << player
  end

  def empty?
    players.empty?
  end

  def start
    deal_cards
  end

  def players_needed
    players_needed_to_start - players.count
  end

  def play_round(target, request)
    matching_cards = get_matching_cards(target, request)
    take_cards_from_player(matching_cards, target)

    drawn_card = fish_card(request) if matching_cards.empty?

    scored_books = current_player.score_books_if_possible unless ignore_books

    self.round_results.push(RoundResult.new(target:, request:, current_player:, matching_cards:, drawn_card:, scored_books:))

    advance_round if drawn_card && drawn_card.rank != request

    round_results.last
  end

  def started?
    deck.count < BASE_DECK_SIZE
  end

  def advance_round
    self.round += 1
  end

  def current_player
    players[round%players.count] unless players.count == 0
  end

  private

  def take_cards_from_player(cards, player)
    player.hand -= cards
    current_player.hand += cards
  end

  def get_matching_cards(target, request)
    target.hand.select { |card| card.rank == request }
  end

  def fish_card(request)
    current_player.add_card_to_hand(deck.draw_card)
  end

  def deal_cards
    players.each do |player|
      BASE_HAND_SIZE.times { player.add_card_to_hand(deck.draw_card) }
    end
  end
end
