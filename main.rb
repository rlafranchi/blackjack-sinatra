require 'rubygems'
require 'sinatra'
require 'shotgun'

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
  
  def card_count(cards)
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
  erb :welcome
end

post '/' do
  session[:player_name] = params[:player_name]
  session[:chip_count] = params[:chip_count]
  redirect '/bet'
end

get '/bet' do
  session[:bet] = 0
  erb :bet
end

post '/bet' do
  session[:bet] = params[:bet]
  if is_a_number?(session[:bet]) && session[:bet].to_f < session[:chip_count].to_f
    redirect '/game'
  else
    @error = "Error"
    redirect '/bet'
  end
end

get '/game' do
  session[:deck] = {}
  session[:deck] = create_deck
  session[:shuffled_deck] = shuffle_deck(session[:deck])
  session[:players_cards] = []
  session[:dealers_cards] = []
  session[:dealers_turn] = false
  session[:players_cards] << session[:shuffled_deck][0]
  session[:dealers_cards] << session[:shuffled_deck][1]
  session[:players_cards] << session[:shuffled_deck][2]
  session[:dealers_cards] << session[:shuffled_deck][3]
  session[:deck_index] = 4
  if count_cards(session[:players_cards]) == 21
    session[:blackjack] = true
  else
    session[:blackjack] = false
  end
  erb :game
end

post '/game' do
  dealer_count = count_cards(session[:dealers_cards])
  player_count = count_cards(session[:players_cards])
  hit = params[:hit]
  stay = params[:stay]
  if hit
    session[:players_cards] << session[:shuffled_deck][session[:deck_index]]
  elsif stay || session[:blackjack] || session[:players_cards] > 21
    session[:dealers_turn] = true
  end
  erb:game
end