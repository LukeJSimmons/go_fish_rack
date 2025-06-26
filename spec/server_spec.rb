require_relative '../spec_helper'

require 'rack/test'
require 'rspec'
require 'capybara'
require 'capybara/dsl'
ENV['RACK_ENV'] = 'test'
require_relative '../server'

RSpec.describe Server do
  include Capybara::DSL
  include Rack::Test::Methods
  def app; Server.new; end

  before do
    Capybara.server = :puma, { Silent: true }
    Capybara.default_driver = :selenium_chrome_headless
    Capybara.app = Server.new
  end

  after do
    Server.game.players.clear
    Server.game.deck.reset
    Server.game.round = 1
    Capybara.reset_sessions!
  end

  it 'is possible to join a lobby' do
    visit '/'
    fill_in :name, with: 'John'
    click_on 'Join'
    expect(page).to have_content('Lobby')
    expect(page).to have_content('John')
  end

  it 'displays inputted name' do
    visit '/'
    fill_in :name, with: 'Billy Bob'
    click_on 'Join'
    expect(page).to have_content('Billy Bob')
  end

 context 'when there are multiple players' do
    let(:session1) { Capybara::Session.new(:selenium_chrome_headless, Server.new) }
    let(:session2) { Capybara::Session.new(:selenium_chrome_headless, Server.new) }

    before do
      [ session1, session2 ].each_with_index do |session, index|
        player_name = "Player #{index + 1}"
        session.visit '/'
        session.fill_in :name, with: player_name
        session.click_on 'Join'
      end
      session2.click_on 'Start Game'
      session1.driver.refresh
      session1.click_on 'Start Game'
    end

    it 'displays current player name' do
      expect(session2).to have_content('Player 2 (you)')
      expect(session1).to have_content('Player 1 (you)')
    end

     it 'allows multiple players to join game' do
      expect(session2).to have_content('Game')
      expect(session2).to have_content('Game')
    end

    it 'displays hand' do
      expect(session1).to have_css("img[src*='/images/cards/AH.svg']")
      expect(session2).to_not have_css("img[src*='/images/cards/AH.svg']")
    end

    it 'advances round on request' do
      expect(session1).to have_content('Round: 1')
      session1.click_on 'Request'
      expect(session1).to have_content('Round: 2')
    end

    it 'adds result to the feed' do
      session1.click_on 'Request'
      expect(session1).to have_content('You asked Player 2 for As')
    end

    it 'only contains valid targets' do
      expect(session2).to have_selector("option", :text=>"Player 1")
      expect(session2).to_not have_selector("option", :text=>"Player 2")
    end

    it 'only contains valid rank requests' do
      expect(session2).to have_selector("option", :text=>"K")
      # expect(session2).to have_select "request", options: ['K','Q','J']
    end
  end

  describe 'API key authorization' do
    before do
      post '/join', { 'name' => 'Caleb' }.to_json, {
        'Accept' => 'application/json',
        'CONTENT_TYPE' => 'application/json'
      }
    end

    it 'returns game status via API' do
      api_key = JSON.parse(last_response.body)['api_key']
      expect(api_key).not_to be_nil
      get '/game', nil, {
        'HTTP_AUTHORIZATION' => "Basic #{Base64.encode64(api_key + ':X')}",
        'Accept' => 'application/json',
        'CONTENT_TYPE' => 'application/json'
      }
      expect(JSON.parse(last_response.body).keys).to include 'players'
    end

    context 'when client does not have API key' do
      context 'GET /game' do
        it 'returns 401 error' do
          get '/game', nil, {
            'HTTP_AUTHORIZATION' => "invalid",
            'Accept' => 'application/json',
            'CONTENT_TYPE' => 'application/json'
          }
          expect(last_response.status).to eq 401
        end
      end

      context 'GET /lobby' do
        it 'returns 401 error' do
          get '/lobby', nil, {
            'HTTP_AUTHORIZATION' => "invalid",
            'Accept' => 'application/json',
            'CONTENT_TYPE' => 'application/json'
          }
          expect(last_response.status).to eq 401
        end
      end

      context 'POST /game' do
        it 'returns 401 error' do
          post '/game', nil, {
            'HTTP_AUTHORIZATION' => "invalid",
            'Accept' => 'application/json',
            'target' => 'Player 2',
            'request' => 'A',
            'CONTENT_TYPE' => 'application/json'
          }
          expect(last_response.status).to eq 401
        end
      end
    end
  end
end
