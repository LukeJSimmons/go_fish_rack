require_relative 'spec_helper'

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

  describe '#score_books_if_possible' do
    context 'when there are no books' do
      it 'returns empty array' do
        expect(player.score_books_if_possible).to eq []
      end
    end

    context 'when there is a book' do
      before do
        player.add_card_to_hand(Card.new('A','H'))
        player.add_card_to_hand(Card.new('A','D'))
        player.add_card_to_hand(Card.new('A','C'))
        player.add_card_to_hand(Card.new('A','S'))
      end

      it 'returns book' do
        expect(player.score_books_if_possible).to eq [[Card.new('A','H'),Card.new('A','D'),Card.new('A','C'),Card.new('A','S')]]
      end

      it 'adds book to books array' do
        player.score_books_if_possible
        expect(player.books.count).to eq 1
      end

      it 'removes books from hand' do
        expect {
          player.score_books_if_possible
        }.to change(player.hand, :count).by (-4)
      end
    end
  end
end
