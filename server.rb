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
    session[:api_key] = player.api_key
    self.class.game.add_player(player)

    self.class.api_keys[player.api_key] = player

    respond_to do |format|
      format.json { json api_key: player.api_key }
      format.html { redirect '/lobby' }
    end
  end

  get '/lobby' do
    error 401 unless session[:current_player].api_key == session_key
    redirect '/' if self.class.game.empty?

    respond_to do |format|
      format.json {  }
      format.html { slim :lobby, locals: { game: self.class.game, current_player: self.class.game.players.find { |player| player.name == session[:current_player].name } } }
    end
  end

  get '/game' do
    error 401 unless session[:current_player].api_key == session_key
    redirect '/' if self.class.game.empty?

    self.class.game.start unless self.class.game.started?

    respond_to do |format|
      format.json { json players: self.class.game.players }
      format.html do
        redirect '/lobby' unless self.class.game.players.count == self.class.game.players_needed_to_start
        slim :game, locals: { game: self.class.game, current_player: self.class.game.players.find { |player| player.name == session[:current_player].name } }
      end
    end
  end

  post '/game' do
    error 401 unless session[:current_player].api_key == session_key
    self.class.game.advance_round

    respond_to do |format|
      format.json { json target: params[:target], request: params[:request] }
      format.html { redirect '/game' }
    end
  end

  private

  def auth
    Rack::Auth::Basic::Request.new(request.env)
  end

  def session_key
    return session[:api_key] unless request.content_type == 'application/json'
    auth.username
  end
end
