require 'round_result'
require 'player'

RSpec.describe RoundResult do
  let(:target) { 'Player 2' }
  let(:request) { 'A' }
  let(:current_player) { Player.new('Player 1') }
  let(:matching_cards) { ['A','A'] }
  let(:drawn_card) { '' }
  let(:result) { RoundResult.new(target:, request:, current_player:, matching_cards:, drawn_card:) }

  describe '#player_action' do
    it 'returns a message containing target and request' do
      expect(result.player_action(current_player)).to include target
      expect(result.player_action(current_player)).to include request
    end
    context 'when displaying to current_player' do
      it 'displays message in the first person' do
        expect(result.player_action(current_player)).to match (/you/i)
      end
    end

    context 'when displaying to opponents' do
      it 'displays message in the third person' do
        expect(result.player_action(:opponents)).to include result.current_player.name
      end
    end
  end

  describe '#player_response' do
    context 'when target has request' do
      it 'returns matching cards' do
        expect(result.player_response(current_player)).to include "2 As"
      end
    end
    context 'when target does not have request' do
      let(:matching_cards) { [] }

      it 'returns go fish' do
        expect(result.player_response(current_player)).to match (/go fish/i)
      end
    end
  end

  describe '#game_response' do
    context 'when target has request' do
      it 'returns empty string' do
        expect(result.game_response).to eq ''
      end
    end

    context 'when target does not have request' do
      let(:drawn_card) { 'A' }

      it 'returns drawn card' do
        expect(result.game_response).to include result.drawn_card
      end
    end
  end
end
