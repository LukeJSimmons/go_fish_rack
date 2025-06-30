require_relative 'deck'
require_relative 'round_result'

class Game
  attr_accessor :players, :deck, :players_needed_to_start, :round, :round_results, :ignore_books, :ignore_shuffle

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
    return if players_needed == 0
    players << player
    player
  end

  def empty?
    players.empty?
  end

  def start
    deck.shuffle! unless ignore_shuffle
    deal_cards
  end

  def players_needed
    players_needed_to_start - players.count
  end

  def play_round(target, request)
    matching_cards = take_cards_from_player(get_matching_cards(target, request), target)

    drawn_cards = matching_cards.empty? && !deck.empty? ? [fish_card(request)] : []

    scored_books = ignore_books ? [] : current_player.score_books_if_possible

    players.each { |player| drawn_cards.push(player.add_card_to_hand(deck.draw_card)) if player.hand.empty? } unless deck.empty?

    self.round_results.push(RoundResult.new(target:, request:, current_player:, matching_cards:, drawn_cards:, scored_books:))

    advance_round if !drawn_cards.empty? && drawn_cards.first.rank != request && current_player.hand.count > 1

    round_results.last
  end

  def winner
    return player_with_most_books unless tie
    player_with_highest_rank_book
  end

  def started?
    deck.count < BASE_DECK_SIZE
  end

  def game_over?
    deck.empty? && players.all? { |player| player.hand.empty? }
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
    cards
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

  def player_with_most_books
    total_books = players.map(&:books).map(&:count)
    players[total_books.find_index(total_books.max)]
  end

  def tie
    players.any? { |player| player.books.count == players.first.books.count && player != players.first }
  end

  def player_with_highest_rank_book
    player_highest_books = players.map do |player|
      player.books.map { |book| book.first.value }.max
    end
    players[player_highest_books.find_index(player_highest_books.max)]
  end
end
