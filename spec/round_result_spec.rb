require 'round_result'

RSpec.describe RoundResult do
  let(:target) { 'Player 2' }
  let(:request) { 'A' }
  let(:result) { RoundResult.new(target, request) }
  describe '#player_action' do
    context 'when displaying to current_player' do
      it 'returns a message containing target and request' do
        expect(result.player_action).to include target
        expect(result.player_action).to include request
      end
    end
  end

  describe '#player_response' do
    context 'when target does not have request' do
      it 'returns go fish' do
        expect(result.player_response).to match (/go fish/i)
      end
    end
  end

  describe '#game_response' do
    context 'when target does not have request' do
      it 'returns drawn card' do
        expect(result.game_response).to match (/drew/i)
      end
    end
  end
end
