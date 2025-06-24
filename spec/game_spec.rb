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

  describe '#start' do
    before do
      game.add_player(player1)
      game.add_player(player2)
    end

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

  describe '#players_needed' do
    it 'returns however many players are needed to start the game' do
      expect(game.players_needed).to eq 2
      game.add_player(Player.new('Player 1'))
      expect(game.players_needed).to eq 1
    end
  end
end
