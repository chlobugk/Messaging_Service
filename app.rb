require 'sinatra'
require 'pg'
require_relative 'functions.rb'
load './local_env.rb' if File.exists?('./local_env.rb')
db_params = {
    host: ENV['host'],
    port: ENV['port'],
    dbname: ENV['db_name'],
    user: ENV['user'],
    password: ENV['password']
}

db = PG::Connection.new(db_params)

get '/' do
	accounts=db.exec("SELECT full_name, username, password FROM accounts");
	erb :home
end

post '/login' do
	redirect '/login'
end

get '/login' do
	erb :login
end

post '/create_account' do
	redirect '/create_account'
end

get '/create_account' do
	message1 = nil
	message2 = nil
	erb :create_account, locals: {message1: message1, message2: message2}
end

get '/invalid_credentials' do
	message1 = 'One or more of your credentials was invalid.'
	message2 = 'Please make sure your password is at least 6 characters.'
	erb :create_account, locals: {message1: message1, message2: message2}
end

get '/username_not_unique' do
	message1 = 'The user name you selected has already been taken.'
	message2 = 'Please choose a different user name.'
	erb :create_account, locals: {message1: message1, message2: message2}
end

post '/created' do
	full_name = params[:full_name]
	username = params[:username]
	password = params[:password]

	if valid_credentials?(full_name, username, password) == false	
		redirect '/invalid_credentials'
	elsif username_not_unique?(username)
		redirect '/username_not_unique'
	else
		#this post adds created account info to database
		accounts=db.exec("SELECT full_name, username, password FROM accounts"); 
		db.exec("INSERT INTO accounts(full_name, username, password) VALUES('#{full_name}', '#{username}', '#{password}')")
		erb :message, locals: {username: username}
	end
end

post '/message' do
	username = params[:username]
	erb :message, locals: {username: username}
end

