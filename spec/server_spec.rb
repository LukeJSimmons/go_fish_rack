require_relative 'spec_helper'

require 'rack/test'
require 'rspec'
require 'capybara'
require 'capybara/dsl'
require 'selenium-webdriver'
ENV['RACK_ENV'] = 'test'
require_relative '../server'

RSpec.describe Server do
  include Capybara::DSL
  include Rack::Test::Methods
  def app; Server.new; end

  before do
    Capybara.register_driver :headless_chrome do |app|
      options = Selenium::WebDriver::Chrome::Options.new
      options.add_argument('--headless')
      options.add_argument('--window-size=1280,1024') # Set your desired width and height
      Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
    end

    Capybara.server = :puma, { Silent: true }
    Capybara.default_driver = :headless_chrome
    Capybara.app = Server.new
  end

  after do
    Server.game.players.clear
    Server.game.deck.reset
    Server.game.round = 0
    Server.game.round_results = []
    Capybara.reset_sessions!
  end

  it 'is possible to join a lobby' do
    visit '/'
    fill_in :name, with: 'John'
    fill_in :number_of_players, with: 2
    click_on 'Join'
    expect(page).to have_content('Lobby')
    expect(page).to have_content('John')
  end

  it 'displays inputted name' do
    visit '/'
    fill_in :name, with: 'Billy Bob'
    fill_in :number_of_players, with: 2
    click_on 'Join'
    expect(page).to have_content('Billy Bob')
  end

 context 'when there are two players' do
    let(:session1) { Capybara::Session.new(:headless_chrome, Server.new) }
    let(:session2) { Capybara::Session.new(:headless_chrome, Server.new) }

    before do
      Server.game.ignore_shuffle = true
      [ session1, session2 ].each_with_index do |session, index|
        player_name = "Player #{index + 1}"
        session.visit '/'
        session.fill_in :name, with: player_name
        session.fill_in :number_of_players, with: 2 if index == 0
        session.click_on 'Join'
      end
      session1.driver.refresh
      session1.driver.refresh
    end

    describe 'player decks' do
      let(:opponent) { Server.game.players.first }

      it 'does not display current player name' do
        expect(session2).to have_no_css('.accordion__label', text: 'Player 2')
        expect(session1).to have_no_css('.accordion__label', text: 'Player 1')
      end

      it 'displays opposing players names' do
        expect(session2).to have_css('.accordion__label', text: 'Player 1')
        expect(session1).to have_css('.accordion__label', text: 'Player 2')
      end

      it 'displays opposing players hands' do
        session2.within '.accordion' do
          session2.find('span', text: 'Player 1').click
          opponent.hand.each do |card|
            expect(session2).to have_css("img[src*='/images/cards/2B.svg']")
          end
        end
      end

      it 'displays opposing player hand count' do
        session2.within '.accordion' do
          session2.find('span', text: 'Player 1').click
          expect(session2).to have_css(".accordion__label", text: opponent.hand.count)
        end
      end

      it 'displays opposing player books count' do
        session2.within '.accordion' do
          session2.find('span', text: 'Player 1').click
          expect(session2).to have_css(".accordion__label", text: opponent.books.count)
        end
      end

      context 'when player has books' do
        before do
          Server.game.players.first.books = [[Card.new('A','H')]]
          session2.driver.refresh
        end

        it 'displays opposing player books count' do
          session2.within '.accordion' do
            session2.find('span', text: 'Player 1').click
            expect(session2).to have_css(".accordion__label", text: opponent.books.count)
          end
        end
      end
    end

     it 'allows multiple players to join game' do
      expect(session2).to have_content('Game')
      expect(session2).to have_content('Game')
    end

    it 'displays session current_player to all players' do
      expect(session2).to have_content("Player 1's turn")
      expect(session1).to have_content("Player 1's turn")
      session1.select 'A', from: 'Request'
      session1.click_on "Request"
      expect(session1).to have_content("Player 2's turn")
      session2.driver.refresh
      expect(session2).to have_content("Player 2's turn")
    end

    describe 'hand' do
      it 'displays hand' do
        Server.game.current_player.hand.each do |card|
          expect(session1).to have_css("img[src*='/images/cards/#{card.rank}#{card.suit}.svg']")
          expect(session2).to have_no_css("img[src*='/images/cards/#{card.rank}#{card.suit}.svg']")
        end
      end

      it 'displays hand with new cards' do
        session_player = Server.game.current_player
        session1.click_on 'Request'
        session2.driver.refresh
        session2.driver.refresh
        session_player.hand.each do |card|
          expect(session1).to have_css("img[src*='/images/cards/#{card.rank}#{card.suit}.svg']")
          expect(session2).to have_no_css("img[src*='/images/cards/#{card.rank}#{card.suit}.svg']")
        end
      end
    end

    describe 'feed' do
      context 'when target does not have request' do
        before do
          session1.select 'A', from: 'Request'
        end

        it 'displays that target does not have request' do
          session1.click_on 'Request'
          expect(session1).to have_content("Go Fish: Player 2 didn't have any As")
        end

        it 'display drawn card to current_player' do
          session1.click_on 'Request'
          expect(session1).to have_content("You drew a J")
          session2.driver.refresh
          expect(session2).to have_content("Player 1 drew a card")
        end

        context 'when deck is empty' do
          before do
            Server.game.deck.clear
          end

          it 'displays that the deck is empty' do
            session1.click_on 'Request'
            expect(session1).to have_content("The deck is empty")
          end
        end
      end

      context 'when target has request' do
        before do
          Server.game.ignore_books = true
          Server.game.ignore_shuffle = true
          session1.select 'K', from: 'Request'
        end

        it 'adds player response to the feed' do
          session1.click_on 'Request'
          expect(session1).to have_content("You took 1 Ks from Player 2")
        end

        it 'does not display game response' do
          session1.click_on 'Request'
          expect(session1).to have_no_css(".feed__bubble--game-response")
        end
      end

      context 'when current_player scores a book' do
        before do
          Server.game.ignore_books = false
          session1.select 'K', from: 'Request'
        end

        it 'displays book message to current_player' do
          session1.click_on 'Request'
          expect(session1).to have_content("You made a book of Ks")
          session2.driver.refresh
          expect(session2).to have_content("Player 1 made a book of Ks")
        end

        it 'displays book in books' do
          session_player = Server.game.current_player
          session1.click_on 'Request'
          session2.driver.refresh
          session_player.books.each do |book|
            expect(session1).to have_css("img[src*='/images/cards/#{book.first.rank}#{book.first.suit}.svg']")
            expect(session2).to have_no_css("img[src*='/images/cards/#{book.first.rank}#{book.first.suit}.svg']")
          end
        end

        it 'displays books in accordion to oppoenent' do
          session1.click_on 'Request'
          session2.driver.refresh
          session2.within '.accordion' do
            session2.find('span', text: 'Player 1').click
          end
          Server.game.players.first.books.each do |book|
            expect(session2).to have_css("img[src*='/images/cards/#{book.first.rank}#{book.first.suit}.svg']")
          end
        end
      end

      context 'when current_player scores multiple books' do
        before do
          session1.select 'K', from: 'Request'
        end

        it 'displays book message to current_player' do
          session1.click_on 'Request'
          expect(session1).to have_content("You made a book of Ks")
          expect(session1).to have_content("You made a book of As")
          session2.driver.refresh
          expect(session2).to have_content("Player 1 made a book of Ks")
          expect(session2).to have_content("Player 1 made a book of As")
        end

        it 'displays books in books' do
          session_player = Server.game.current_player
          session1.click_on 'Request'
          session2.driver.refresh
          session_player.books.each do |book|
            expect(session1).to have_css("img[src*='/images/cards/#{book.first.rank}#{book.first.suit}.svg']")
            expect(session2).to have_no_css("img[src*='/images/cards/#{book.first.rank}#{book.first.suit}.svg']")
          end
        end
      end
    end

    describe 'feed__request-form' do
      it 'only contains valid targets' do
        expect(session2).to have_selector("option", :text=>"Player 1")
        expect(session2).to_not have_selector("option", :text=>"Player 2")
      end

      it 'only contains valid rank requests' do
        expect(session2).to have_selector("option", :text=>"K")
      end

      it 'disables the request button when it is not your turn' do
        expect(session2).to have_button("Request", disabled: true)
        expect(session1).to have_button("Request", disabled: false)
      end
    end

    describe 'win state' do
      context 'when player 1 is the winner' do
        before do
          Server.game.deck.clear
          Server.game.players.each { |player| player.hand.clear }
          Server.game.players.first.books = [[Card.new('A','H')]]
          session1.driver.refresh
        end

        it 'displays player 1' do
          expect(session1).to have_content("Player 1 Wins")
        end
      end

      context 'when player 2 is the winner' do
        before do
          Server.game.deck.clear
          Server.game.players.each { |player| player.hand.clear }
          Server.game.players[1].books = [[Card.new('A','H')]]
          session1.driver.refresh
        end

        it 'displays player 2' do
          expect(session1).to have_content("Player 2 Wins")
        end
      end
    end
  end

  fdescribe 'API key authorization' do
    context 'when client has API key' do
      context 'lobby' do
        before do
          post '/join', { 'name' => 'Caleb', 'number_of_players' => '2' }.to_json, {
            'Accept' => 'application/json',
            'CONTENT_TYPE' => 'application/json'
          }
        end

        it 'returns game status via API' do
          api_key = JSON.parse(last_response.body)['api_key']
          expect(api_key).not_to be_nil
          get '/game', nil, {
            'HTTP_API_KEY' => api_key,
            'Accept' => 'application/json',
            'CONTENT_TYPE' => 'application/json'
          }
          expect(JSON.parse(last_response.body).keys).to include 'players'
          expect(JSON.parse(last_response.body).keys).to include 'players_needed'
        end
      end

      context 'game' do
        before do
          post '/join', { 'name' => 'Caleb', 'number_of_players' => '2' }.to_json, {
            'Accept' => 'application/json',
            'CONTENT_TYPE' => 'application/json'
          }
          post '/join', { 'name' => 'Joe' }.to_json, {
            'Accept' => 'application/json',
            'CONTENT_TYPE' => 'application/json'
          }
        end

        it 'returns game status via API' do
          api_key = JSON.parse(last_response.body)['api_key']
          expect(api_key).not_to be_nil
          get '/game', nil, {
            'HTTP_API_KEY' => api_key,
            'Accept' => 'application/json',
            'CONTENT_TYPE' => 'application/json'
          }
          expect(JSON.parse(last_response.body).keys).to include 'hand'
          expect(JSON.parse(last_response.body).keys).to include 'players'
          expect(JSON.parse(last_response.body).keys).to include 'round_result'
        end
      end

      context 'game over' do
        before do
          post '/join', { 'name' => 'Caleb', 'number_of_players' => '2' }.to_json, {
            'Accept' => 'application/json',
            'CONTENT_TYPE' => 'application/json'
          }
          post '/join', { 'name' => 'Joe' }.to_json, {
            'Accept' => 'application/json',
            'CONTENT_TYPE' => 'application/json'
          }
          allow(Server.game).to receive(:game_over?).and_return true
        end

        it 'returns game status via API' do
          api_key = JSON.parse(last_response.body)['api_key']
          expect(api_key).not_to be_nil
          get '/game', nil, {
            'HTTP_API_KEY' => api_key,
            'Accept' => 'application/json',
            'CONTENT_TYPE' => 'application/json'
          }
          expect(JSON.parse(last_response.body).keys).to include 'winner'
        end
      end
    end

    context 'when client does not have API key' do
      context 'GET /game' do
        it 'returns 401 error' do
          get '/game', nil, {
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
            'CONTENT_TYPE' => 'application/json',
            'target' => 'Player 2',
            'request' => 'A'
          }
          expect(last_response.status).to eq 401
        end
      end
    end

    context 'when client has opponent API key' do
      before do
        post '/join', { 'name' => 'Caleb', 'number_of_players' => '2' }.to_json, {
          'Accept' => 'application/json',
          'CONTENT_TYPE' => 'application/json'
        }

        post '/join', { 'name' => 'Joe' }.to_json, {
          'Accept' => 'application/json',
          'CONTENT_TYPE' => 'application/json'
        }
      end

      context 'GET /game' do
        it 'returns 401 error' do
          api_key = Server.game.players.first.api_key
          get '/game', nil, {
            'HTTP_AUTHORIZATION' => "Basic #{Base64.encode64(api_key + ':X')}",
            'Accept' => 'application/json',
            'CONTENT_TYPE' => 'application/json'
          }
          expect(last_response.status).to eq 401
        end
      end

      context 'POST /game' do
        it 'returns 401 error' do
          api_key = Server.game.players.first.api_key
          post '/game', nil, {
            'HTTP_AUTHORIZATION' => "Basic #{Base64.encode64(api_key + ':X')}",
            'Accept' => 'application/json',
            'CONTENT_TYPE' => 'application/json'
          }
          expect(last_response.status).to eq 401
        end
      end
    end
  end

  context 'when there are three players' do
    let(:session1) { Capybara::Session.new(:headless_chrome, Server.new) }
    let(:session2) { Capybara::Session.new(:headless_chrome, Server.new) }
    let(:session3) { Capybara::Session.new(:headless_chrome, Server.new) }

    context 'when players_needed is two' do
      before do
        [ session1, session2, session3 ].each_with_index do |session, index|
          player_name = "Player #{index + 1}"
          session.visit '/'
          session.fill_in :name, with: player_name
          session.fill_in :number_of_players, with: 2 if index == 0
          session.click_on 'Join'
        end
        session1.driver.refresh
        session1.driver.refresh
      end

      it 'does not allow multiple players to join game' do
        expect(session1).to have_content('Game')
        expect(session2).to have_content('Game')
        expect(session3).to_not have_content('Game')
      end
    end

    context 'when players_needed is three' do
      before do
        [ session1, session2, session3 ].each_with_index do |session, index|
          player_name = "Player #{index + 1}"
          session.visit '/'
          session.fill_in :name, with: player_name
          session.fill_in :number_of_players, with: 3 if index == 0
          session.click_on 'Join'
        end
        session1.driver.refresh
        session1.driver.refresh
        session2.driver.refresh
      end

      it 'allows multiple players to join game' do
        expect(session1).to have_content('Game')
        expect(session2).to have_content('Game')
        expect(session3).to have_content('Game')
      end
    end
  end
end
