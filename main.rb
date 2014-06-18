require 'rubygems'
require 'sinatra'
require 'shotgun'

set :sessions, true

get '/' do
  erb :welcome
end