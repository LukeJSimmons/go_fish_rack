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
    redirect '/game' if self.class.game.players.count >= 2

    slim :lobby, locals: { game: self.class.game }
  end

  get '/game' do
    redirect '/' if self.class.game.empty?

    respond_to do |format|
      format.json { json players: self.class.game.players }
      format.html { slim :game, locals: { game: self.class.game, current_player: session[:current_player] } }
    end
  end

  private

  def api_key(player)
    Base64.urlsafe_encode64(player.name)
  end
end
