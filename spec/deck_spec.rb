require 'deck'

RSpec.describe Deck do
  let(:deck) { Deck.new }
  it 'starts with 52 cards' do
    expect(deck.cards.count).to eq 52
  end
end
