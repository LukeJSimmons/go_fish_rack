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
    respond_to do |format|
      format.html { slim :index }
    end
  end

  post '/join' do
    player = Player.new(params['name'], Base64.urlsafe_encode64(params['name']))
    session[:current_player] = self.class.game.add_player(player)
    session[:api_key] = player.api_key
    self.class.api_keys[player.api_key] = player

    respond_to do |format|
      format.json { json api_key: player.api_key }
      format.html { redirect '/lobby' }
    end
  end

  get '/lobby' do
    error 401 unless is_valid_player?(session[:current_player])

    respond_to do |format|
      format.json {  }
      format.html { slim :lobby, locals: { game: self.class.game, current_player: self.class.game.players.find { |player| player.name == session[:current_player].name } } }
    end
  end

  get '/game' do
    error 401 unless is_valid_player?(session[:current_player])
    redirect '/lobby' unless self.class.game.players.count == self.class.game.players_needed_to_start

    self.class.game.start unless self.class.game.started?

    respond_to do |format|
      format.json { json players: self.class.game.players, current_player: session[:current_player] }
      format.html { slim :game, locals: { game: self.class.game, current_player: self.class.game.players.find { |player| player.name == session[:current_player].name } } }
    end
  end

  post '/game' do
    error 401 unless is_valid_player?(session[:current_player])
    round_result = self.class.game.play_round(get_player_by_name(params[:target]), params[:request])

    respond_to do |format|
      format.json { json round_result: round_result }
      format.html { redirect '/game' }
    end
  end

  private

  def auth
    Rack::Auth::Basic::Request.new(request.env)
  end

  def session_key
    return session[:api_key] unless request.content_type == 'application/json'
    return :invalid_key unless request.env["HTTP_AUTHORIZATION"]
    auth.username
  end

  def is_valid_player?(player)
    player&.api_key == session_key && player
  end

  def get_player_by_name(name)
    self.class.game.players.find { |player| player.name == name }
  end
end
