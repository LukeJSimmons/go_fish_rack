require_relative '../spec_helper'

require 'round_result'
require 'player'
require 'card'

RSpec.describe RoundResult do
  let(:target) { Player.new('Player 2') }
  let(:request) { 'A' }
  let(:current_player) { Player.new('Player 1') }
  let(:matching_cards) { ['A','A'] }
  let(:drawn_card) { nil }
  let(:scored_books) { [] }
  let(:result) { RoundResult.new(target:, request:, current_player:, matching_cards:, drawn_card:, scored_books:) }

  describe '#player_action' do
    context 'when displaying to current_player' do
      it 'returns a message containing target and request' do
        expect(result.player_action(current_player)).to include 'Player 2'
        expect(result.player_action(current_player)).to include request
      end

      it 'displays message in the second person' do
        expect(result.player_action(current_player)).to match (/you/i)
      end
    end

    context 'when displaying to target' do
      it 'displays target in the second person' do
        expect(result.player_action(target)).to match (/you/i)
      end
    end

    context 'when displaying to opponents' do
      it 'displays message in the third person' do
        expect(result.player_action(:opponents)).to include 'Player 1'
      end
    end
  end

  describe '#player_response' do
    context 'when target has request' do
      it 'returns matching cards' do
        expect(result.player_response(current_player)).to include "2 As"
      end

      context 'when displaying to current_player' do
        it 'displays message in the second person' do
          expect(result.player_response(current_player)).to match (/you/i)
        end
      end

      context 'when displaying to target' do
        it 'displays object in the second person' do
          expect(result.player_response(target)).to match (/you/i)
        end
      end
    end

    context 'when target does not have request' do
      let(:matching_cards) { [] }

      it 'returns go fish' do
        expect(result.player_response(current_player)).to match (/go fish/i)
      end

      it "displays didn't instead of don't" do
        expect(result.player_response(current_player)).to_not match (/don't/i)
        expect(result.player_response(current_player)).to match (/didn't/i)
      end

      context 'when displaying to target' do
        it 'displays object in the second person' do
          expect(result.player_response(target)).to match (/you/i)
        end

        it "displays don't instead of didn't" do
          expect(result.player_response(target)).to match (/don't/i)
          expect(result.player_response(target)).to_not match (/didn't/i)
        end
      end
    end
  end

  describe '#game_response' do
    context 'when target has request' do
      it 'returns nil' do
        expect(result.game_response(result.current_player)).to eq nil
      end
    end

    context 'when target does not have request' do
      let(:drawn_card) { Card.new('A','H') }

      context 'when displaying to current_player' do
        it 'returns drawn card' do
          expect(result.game_response(result.current_player)).to include drawn_card.rank
        end
      end

      context 'when displaying to opponents' do
        it 'does not return drawn card' do
          expect(result.game_response(result.target)).to_not include drawn_card.rank
        end
      end
    end
  end
end
