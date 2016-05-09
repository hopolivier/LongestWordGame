require 'json'
require 'open-uri'

class LongestWordController < ApplicationController
  def game
    @grid = generate_grid(9)
    @start_time = Time.now
  end

  def score
    @start_time = params[:start_time]
    @grid = params[:grid].upcase
    @guess = params[:guess].upcase
    @end_time = Time.now
    result = run_game(@guess, @grid, @start_time, @end_time)
    @time = (result[:time] / 1000).round.to_s
    @translation = result[:translation]
    @message = result[:message]
    @score = result[:score].round
    session[:game_number] = session[:game_number].nil? ? 1 : session[:game_number] + 1
    # session[:score_array] << score
    # rails
    # @average = session[:score_array].reduce(:+).to_f / session[:score_array].length
    @sessions = session[:game_number]
  end

  def reset
    reset_session
  end

private

def generate_grid(grid_size)
  Array.new(grid_size) { ('A'..'Z').to_a[rand(26)] }
end


def included?(guess, grid)
  guess_array = guess.split('')
  grid_array = grid.split('')
  grid_array.all? { |letter| grid_array.count(letter) >= guess_array.count(letter) }
  # the_grid = grid.clone
  # guess.chars.each do |letter|
  #   the_grid.delete_at(the_grid.index(letter)) if the_grid.include?(letter)
  # end
  # grid.size == guess.size + the_grid.size
end

def compute_score(attempt, time_taken)
      # rails
  (time_taken > 60_000.0) ? 0 : attempt.size * (1.0 - time_taken / 60_000.0)
end

def get_translation(word)
  response = open("http://api.wordreference.com/0.8/80143/json/enfr/#{word.downcase}")
  json = JSON.parse(response.read.to_s)
  json['term0']['PrincipalTranslations']['0']['FirstTranslation']['term'] unless json["Error"]
end

def score_and_message(attempt, translation, grid, time)
  if translation
    if included?(attempt.upcase, grid)
      score = compute_score(attempt, time)
      [score, "well done"]
    else
      [0, "not in the grid"]
    end
  else
    [0, "not an english word"]
  end
end

def run_game(attempt, grid, start_time, end_time)
  result = { time: end_time - DateTime.parse(start_time) }

  result[:translation] = get_translation(attempt)
  result[:score], result[:message] = score_and_message(
    attempt, result[:translation], grid, result[:time])

  result
end

end



