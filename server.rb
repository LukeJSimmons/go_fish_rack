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
    redirect '/' if self.class.game.players_needed == 0
    player = Player.new(params['name'], Base64.urlsafe_encode64(params['name']))
    self.class.game.players_needed_to_start = params["number_of_players"].to_i if self.class.game.players.empty?
    session[:current_player] = self.class.game.add_player(player)
    session[:api_key] = player.api_key
    self.class.api_keys[player.api_key] = player

    respond_to do |format|
      format.json { json api_key: player.api_key }
      format.html { redirect '/game' }
    end
  end

  get '/game' do
    error 401 unless is_valid_player?(session[:current_player])

    self.class.game.start if self.class.game.players_needed == 0 && !self.class.game.started?

    respond_to do |format|
      format.json { game_state }
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

  def api_key
    return auth.username if request.content_type == 'application/json'
    session[:api_key]
  end

  def is_valid_player?(player)
    player = player_by_api_key unless player
    player&.api_key == api_key && player
  end

  def get_player_by_name(name)
    self.class.game.players.find { |player| player.name == name }
  end

  def game_state
    return json players: self.class.game.players.map(&:attributes), players_needed: self.class.game.players_needed unless self.class.game.started?
    return json players: self.class.game.players.map(&:attributes), hand: player_by_api_key.hand.map(&:rank), round_result: self.class.game.round_results.last&.attributes unless self.class.game.game_over?
    json winner: self.class.game.winner
  end

  def player_by_api_key
    self.class.api_keys[api_key]
  end
end
