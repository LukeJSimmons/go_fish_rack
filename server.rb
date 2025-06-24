require 'sinatra'
require 'sinatra/json'
require 'sinatra/respond_with'
require 'rack/contrib'
require_relative 'lib/game'
require_relative 'lib/player'

class Server < Sinatra::Base
  enable :sessions
  register Sinatra::RespondWith
  use Rack::JSONBodyParser

  def self.game
    @@game ||= Game.new
  end

  def self.api_keys
    @@api_keys ||= {}
  end

  get '/' do
    slim :index
  end

  post '/join' do
    player = Player.new(params['name'])
    session[:current_player] = player
    self.class.game.add_player(player)

    new_api_key = api_key(player)
    self.class.api_keys[new_api_key] = player

    respond_to do |format|
      format.json { json api_key: new_api_key }
      format.html { redirect '/lobby' }
    end
  end

  get '/lobby' do
    redirect '/' if self.class.game.empty?
    # redirect '/game' if self.class.game.players.count == self.class.game.players_needed_to_start

    respond_to do |format|
      format.html { slim :lobby, locals: { game: self.class.game, current_player: self.class.game.players.find { |player| player.name == session[:current_player].name } } }
    end
  end

  get '/game' do
    redirect '/' if self.class.game.empty?

    self.class.game.start

    respond_to do |format|
      format.json { json players: self.class.game.players }
      format.html do
        redirect '/lobby' unless self.class.game.players.count == self.class.game.players_needed_to_start
        slim :game, locals: { game: self.class.game, current_player: self.class.game.players.find { |player| player.name == session[:current_player].name } }
      end
    end
  end

  private

  def api_key(player)
    Base64.urlsafe_encode64(player.name)
  end
end
