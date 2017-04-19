require 'sinatra'
require 'pg'
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
	erb :login
end

post '/create_account' do 
	erb :create_account
end


post '/created' do
	#this post adds created account info to database
	full_name = params[:full_name]
	username = params[:username]
	password = params[:password] 
	db.exec("INSERT INTO accounts(full_name, username, password) VALUES('#{full_name}', '#{username}', '#{password}')")
	erb :login
end

post 'message' do
	erb :message
end

