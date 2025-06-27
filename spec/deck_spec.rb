require 'deck'

RSpec.describe Deck do
  let(:deck) { Deck.new }
  it 'starts with 52 cards' do
    expect(deck.cards.count).to eq 52
  end

  describe '#shuffle!' do
    it 'shuffles the deck' do
      expect(deck).to eq Deck.new
      deck.shuffle!
      expect(deck).to_not eq Deck.new
    end
  end
end
