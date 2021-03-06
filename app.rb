#encoding: utf-8
require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'sqlite3'

def init_db
	@db = SQLite3::Database.new 'lepra.db'
	@db.results_as_hash = true
end

before do
	init_db
end

configure do
	init_db

	@db.execute 'CREATE TABLE IF NOT EXISTS
		posts (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			created_date DATE,
			content TEXT,
			author TEXT
		)'

	@db.execute 'CREATE TABLE IF NOT EXISTS
		comments (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			post_id INTEGER,
			created_date DATE,
			content TEXT,
			author TEXT
		)'
end


get '/' do
	# получаем список постов в обратном порядке
	@results = @db.execute 'SELECT * FROM posts ORDER BY id DESC'
	erb :index
end

get '/new' do
	erb :new
end

post '/new' do
	content = params[:content]
	username = params[:username]

	# создаём хэш ошибок
	hh_err = {:username => "Введите имя", :content => "Не могу запостить пустоту"}

	# проверка на длину передаваемых данных
	@error = hh_err.select {|key,_| params[key] == ''}.values.join(", ")
	if @error != ''
		return erb :new
	end

	# сохранение данных в базу
	@db.execute 'INSERT INTO posts (content, created_date, author) VALUES (?, datetime(), ?)', [content, username]
	redirect to '/'
end

get '/post/:post_id' do
	post_id = params[:post_id]

	results = @db.execute 'SELECT * FROM posts WHERE id = ?', [post_id]
	@row = results[0]

	# выбираем комментарии для нашего поста
	@comments = @db.execute 'SELECT * FROM comments WHERE post_id = ? ORDER BY id', [post_id]

	erb :post
end

post '/post/:post_id' do
	post_id = params[:post_id]
	content = params[:content]
	username = params[:username]

	@db.execute 'INSERT INTO comments (post_id, created_date, content, author) VALUES (?, datetime(), ?, ?)', [post_id, content, username]

	redirect to('/post/' + post_id)
end