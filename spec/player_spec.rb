require 'player'
require 'card'

RSpec.describe Player do
  let(:player) { Player.new('Player 1') }

  describe '#add_card_to_hand' do
    it 'sorts hand by rank' do
      player.add_card_to_hand(Card.new('2','H'))
      player.add_card_to_hand(Card.new('Q','H'))
      player.add_card_to_hand(Card.new('2','H'))
      expect(player.hand).to eq player.hand.sort
    end
  end
end
