require 'sinatra'
require 'pg'
Dir["/messaging_service/gplus-quickstart-ruby/*.rb"].each {|file| require file }
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
	erb :home
end

post '/login' do
	erb :login
end

post '/create_account' do
	full_name = params[:full_name]
	username = params[:username]
	password = params[:password]
	db.exec("INSERT INTO accounts(full_name, username, password) VALUES('#{full_name}', '#{username}', '#{password}')"); 
	erb :create_account
end

post '/message' do
	erb :message
end

