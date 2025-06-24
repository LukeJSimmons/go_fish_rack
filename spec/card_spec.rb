require 'card'

RSpec.describe Card do
  let(:card) { Card.new('Q','H') }
  it 'has a rank and suit' do
    expect(card).to respond_to :rank
    expect(card).to respond_to :suit
  end
end
