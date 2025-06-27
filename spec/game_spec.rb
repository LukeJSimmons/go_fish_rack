require_relative '../spec_helper'

require 'game'
require 'player'

RSpec.describe Game do
  let(:game) { Game.new }
  let(:player1) { Player.new('Player 1') }
  let(:player2) { Player.new('Player 2') }

  describe '#empty' do
    context 'when there are players' do
      it 'returns false' do
        game.add_player('Player 1')
        expect(game.empty?).to eq false
      end
    end

    context 'when there are no players' do
      it 'returns true' do
        expect(game.empty?).to eq true
      end
    end
  end

  describe '#players_needed' do
    it 'returns however many players are needed to start the game' do
      expect(game.players_needed).to eq 2
      game.add_player(Player.new('Player 1'))
      expect(game.players_needed).to eq 1
    end
  end

  context 'when there are players' do
    before do
        game.add_player(player1)
        game.add_player(player2)
      end

    describe '#start' do
      it 'deals seven cards to each player' do
        game.start
        expect(game.players.first.hand.count).to eq 7
        expect(game.players[1].hand.count).to eq 7
      end

      it 'deals cards from the deck' do
        expect {
          game.start
      }.to change(game.deck.cards, :count).by (-14)
      end
    end

    describe '#current_player' do
      context 'on round 1' do
        it 'returns player 1' do
          expect(game.current_player).to eq game.players.first
        end
      end

      context 'on round 2' do
        it 'returns player 2' do
          game.advance_round
          expect(game.current_player).to eq game.players[1]
        end
      end
    end

    describe '#play_round' do
      let(:target) { game.players.last }
      let(:request) { 'K' }

      it 'returns a RoundResult object' do
        round_result = game.play_round(target, request)
        expect(round_result).to respond_to :target
      end

      it 'adds round result to round_results' do
        expect {
          game.play_round(target, request)
      }.to change(game.round_results, :count).by 1
      end

      context 'when target has matching_cards' do
        let(:round) { game.play_round(target, request) }
        before do
          game.ignore_books = true
          game.start
        end

        it 'removes cards from target hand' do
          expect(round.target.hand.count).to eq 6
        end

        it 'adds cards to current_player hand' do
          expect(round.current_player.hand.count).to eq 8
        end

        it 'does not increment round' do
          expect {
            game.play_round(target, request)
          }.to_not change(game, :round)
        end

        context 'when taken cards leave targets hand empty' do
          let(:target) {
            game.players.last.hand.clear
            game.players.last
           }

          it 'adds a card from the deck to the players hand' do
            expect(round.target.hand.count).to eq 1
          end
        end

        context 'when matching_cards makes a book' do
          before do
            game.ignore_books = false
          end

          it 'removes book from hand' do
            expect(round.current_player.hand.map(&:rank)).to_not include "K"
          end

          context 'when hand is empty after scoring book' do
            it 'adds a card from the deck to the players hand' do
              expect(round.current_player.hand.count).to eq 1
            end

            it 'does not increment round' do
              expect {
                game.play_round(target, request)
              }.to_not change(game, :round)
            end

            context 'when deck is empty' do
              before do
                game.deck.cards.clear
              end

              it 'does not draw a card' do
                expect(game.play_round(target, request).drawn_cards).to eq []
              end
            end
          end
        end
      end

      context 'when target does not have matching_cards' do
        let(:request) { 'A' }
        let(:round) { game.play_round(target, request) }
        before do
          game.ignore_books = true
          game.start
        end

        it 'adds a card from the deck to current_player hand' do
          expect(round.current_player.hand.count).to eq 8
        end

        context 'when drawn_card is request' do
          before do
            game.deck.cards = [Card.new('A','H')]
          end

          it 'does not increment round' do
            expect {
              game.play_round(target, request)
            }.to_not change(game, :round)
          end
        end

        context 'when drawn_card is not request' do
          before do
            game.deck.cards = [Card.new('10','H')]
          end

          it 'increments round by 1' do
            expect {
              game.play_round(target, request)
          }.to change(game, :round).by 1
          end
        end

        context 'when deck is empty' do
          before do
            game.deck.cards.clear
          end

          it 'does not draw a card' do
            expect(game.play_round(target, request).drawn_cards).to eq []
          end
        end
      end
    end

    describe '#started?' do
      context 'when game has not started' do
        it 'returns false' do
          expect(game.started?).to eq false
        end
      end

      context 'when game has started' do
        it 'returns true' do
          game.deck.draw_card
          expect(game.started?).to eq true
        end
      end
    end
  end
end
