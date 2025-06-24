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
    it 'displays current player name' do
      session1 = Capybara::Session.new(:selenium_chrome_headless, Server.new)
      session2 = Capybara::Session.new(:selenium_chrome_headless, Server.new)
      [ session1, session2 ].each_with_index do |session, index|
        player_name = "Player #{index + 1}"
        session.visit '/'
        session.fill_in :name, with: player_name
        session.click_on 'Join'
      end
      expect(session2).to have_content('You are Player 2')
      session1.refresh
      expect(session1).to have_content('You are Player 1')
    end

     it 'allows multiple players to join game' do
      session1 = Capybara::Session.new(:selenium_chrome_headless, Server.new)
      session2 = Capybara::Session.new(:selenium_chrome_headless, Server.new)
      [ session1, session2 ].each_with_index do |session, index|
        player_name = "Player #{index + 1}"
        session.visit '/'
        session.fill_in :name, with: player_name
        session.click_on 'Join'
        expect(session).to have_css('.players__player', text: player_name)
      end
      session1.driver.refresh
      expect(session1).to have_content('Players')
      expect(session2).to have_content('Player 1')
      expect(session1).to have_content('Player 2')
    end

    it 'displays hand' do
      session1 = Capybara::Session.new(:selenium_chrome_headless, Server.new)
      session2 = Capybara::Session.new(:selenium_chrome_headless, Server.new)
      [ session1, session2 ].each_with_index do |session, index|
        player_name = "Player #{index + 1}"
        session.visit '/'
        session.fill_in :name, with: player_name
        session.click_on 'Join'
      end
      expect(session2).to have_content('is, K')
      session1.driver.refresh
      expect(session1).to have_content('is, A')
      session2.driver.refresh
      expect(session2).to_not have_content('is, A')
    end
  end

  it 'returns game status via API' do
    post '/join', { 'name' => 'Caleb' }.to_json, {
      'Accept' => 'application/json',
      'CONTENT_TYPE' => 'application/json'
    }
    api_key = JSON.parse(last_response.body)['api_key']
    expect(api_key).not_to be_nil
    get '/game', nil, {
      'HTTP_AUTHORIZATION' => "Basic #{Base64.encode64(api_key + ':X')}",
      'Accept' => 'application/json'
    }
    expect(JSON.parse(last_response.body).keys).to include 'players'
  end
end
