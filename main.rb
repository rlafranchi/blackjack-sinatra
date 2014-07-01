require 'rubygems'
require 'sinatra'
# require 'shotgun'
# require 'pry'

set :sessions, true

helpers do
  def is_a_number?(s)
    s.to_s.match(/\A[+-]?\d+?(\.\d+)?\Z/) == nil ? false : true 
  end
  
  def create_deck
    suits = ['clubs', 'diamonds', 'hearts', 'spades']
    card_values = [11, 2, 3, 4, 5, 6, 7, 8, 9, 10, 10, 10, 10]
    deck = {}
    suits.each do |suit|
      card_values.each_with_index do |v,i|
        if i == 0
          deck[suit + '_ace'] = v
        elsif i == 10
          deck[suit + '_jack'] = v
        elsif i == 11
          deck[suit + '_queen'] = v
        elsif i == 12
          deck[suit + '_king'] = v
        else
          deck[suit + '_' + v.to_s] = v
        end
      end
    end
    return deck
  end

  def shuffle_deck(d)
    return d.keys.shuffle
  end
  
  def count_cards(cards)
    deck = create_deck
    v = 0
    cards.each do |k|
      v += deck[k]
    end
    if v > 21
      v = 0
      cards.each do |k|
        if deck[k] == 11
          v += 1
        else
          v += deck[k]
        end
      end
    end 
    return v
  end
  
end

get '/' do
  @error = ( session[:error] ) ? session[:error] : nil
  erb :welcome
end

post '/' do
  session[:player_name] = params[:player_name]
  session[:chip_count] = params[:chip_count].to_f
  if is_a_number?(session[:chip_count])
    session[:error] = nil
    redirect '/bet'
  else
    session[:error] = "Invalid. Please enter a number for the amount of chips."
    redirect '/'
  end
end

get '/bet' do
  session[:bet] = 0
  @error = ( session[:error] ) ? session[:error] : nil
  erb :bet
end

post '/bet' do
  session[:bet] = params[:bet].to_f
  if is_a_number?(session[:bet]) && session[:bet] <= session[:chip_count]
    session[:error] = nil
    redirect '/game'
  else
    session[:error] = "Invalid. Make another bet:"
    redirect '/bet'
  end
end

get '/game' do
  session[:deck] = {}
  session[:deck] = create_deck
  session[:shuffled_deck] = shuffle_deck(session[:deck])
  session[:players_cards] = []
  session[:dealers_cards] = []
  session[:player_count] = 0
  session[:dealer_count] = 0
  session[:game_over] = false
  session[:dealers_turn] = false
  session[:players_cards] << session[:shuffled_deck][0]
  session[:dealers_cards] << session[:shuffled_deck][1]
  session[:players_cards] << session[:shuffled_deck][2]
  session[:dealers_cards] << session[:shuffled_deck][3]
  session[:deck_index] = 4
  session[:player_count] = count_cards(session[:players_cards])
  if session[:player_count] == 21
    session[:blackjack] = true
    session[:dealers_turn] = true
    while session[:dealer_count] < 17
      session[:dealers_cards] << session[:shuffled_deck][session[:deck_index]]
      session[:dealer_count] = count_cards(session[:dealers_cards])
      session[:deck_index] += 1
    end
  else
    session[:blackjack] = false
  end
  @blackjack = session[:blackjack]
  if @blackjack && session[:dealer_count] == 21
    @tie = "It's a tie"
  elsif @blackjack
    @win = "You Win!"
    session[:chip_count] += 1.5 * session[:bet]
  end
  erb :game
end

post '/game' do

  hit = params[:hit]
  stay = params[:stay]
  
  if hit
    session[:players_cards] << session[:shuffled_deck][session[:deck_index]]
    session[:player_count] = count_cards(session[:players_cards])
    session[:deck_index] += 1
  end
  
  if session[:player_count] > 21
    session[:dealer_count] = count_cards(session[:dealers_cards])
    @lose = "Bust! Dealer Shows cards."
    session[:chip_count] -= session[:bet]
    session[:dealers_turn] = true
  elsif stay || session[:dealers_turn] == true || session[:player_count] == 21 || session[:blackjack]
    session[:dealers_turn] = true
    # dealers turn
    session[:dealer_count] = count_cards(session[:dealers_cards])
    while session[:dealer_count] < 17
      session[:dealers_cards] << session[:shuffled_deck][session[:deck_index]]
      session[:dealer_count] = count_cards(session[:dealers_cards])
      session[:deck_index] += 1
    end

    if session[:dealer_count] > 21
      @win = "Dealer busts! You Win"
      session[:chip_count] += session[:bet]
    elsif session[:player_count] == session[:dealer_count]
      @tie = "It's a Tie!"
    # chip count doesn't change
    elsif session[:player_count] > session[:dealer_count]
      @win = "You Win!"
      session[:chip_count] += session[:bet]
    elsif session[:player_count] < session[:dealer_count]
      @lose = "You Lose! The House always wins! HaHaHa.."
      session[:chip_count] -= session[:bet]
    end
  end
  
  unless params[:layout]
    erb :game, layout: false
  else
    erb :game
  end
end

post '/game-over' do
  if params[:play_again]
    redirect '/bet'
  elsif params[:donot_play_again]
    session[:game_over] = true
    erb :game
 
  elsif params[:buy_more]
    session[:chip_count] = params[:buy_more].to_f
    # binding.pry
    redirect '/bet'
  end
end