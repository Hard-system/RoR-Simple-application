require 'sinatra'
require 'data_mapper'



DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/wiki.db")

class User
	include DataMapper::Resource
	property :id, Serial
	property :username, Text, :required => true, :unique_index => true, :length => 5..12 
	property :password, BCryptHash, :required => true 
	property :date_joined, DateTime
	property :edit, Boolean, :required =>true, :default =>true
	property :admin, Boolean, :required =>true, :default =>false
	validates_uniqueness_of :username
end

DataMapper.finalize.auto_upgrade!

	

@info= ""

def readFile(wiki)
	info = ""
	file=File.open(wiki)
	file.each do |line|
		info = info + line
	end
	file.close
	
end

get '/' do 
	info = "Hello there! "
	#----------------give the number of the letters and characters
	@info = File.read('wiki.txt')
  	@letters = @info.scan(/[a-zA-Z]/).length
  	@characters = @info.gsub(/\s+/, '').length                      
  	#------------------------------gives the number of words 
	@words = @info.scan(/(\W|-)+\D/).length
	#----------------------- counting lines
	lines = File.readlines('wiki.txt')
	@line_count = lines.size
	text = lines.join
	#------------------------> number of sentences
	@sentence = @info.split(/\.|\? |!/).length
	@sentences = @sentence - 1
	#------------------------> number of paragraph
	@paragraph_count = @info.split(/\n\n/).length
	erb :home
end

#---------------------------opens the About page
get '/about' do
	erb :about
end

#opens the Video page
get '/video' do
	def time
		current_time = Time.new
		@curr_time = current_time.strftime("%H:%M")
	end

	def day 
		current_day = Time.new
		current = current_day.strftime("%A")
	end

	def info
		"Hello World! Today is #{day} and it is #{time} o'clock!"
	end
	@info1=info	

	erb :video
end

#opens the Edit page
get '/edit' do
	protected!
	info = ""
	file = File.open("wiki.txt")
	file.each do |line|
		info = info + line
	end
	file.close
	@info = info
	erb :edit
end


#update the info from Edit into the Home page and also records the file when has been changed the time and the user that has done that!
put '/edit' do
	info = "#{params[:message]}"
	@info = info
	file= File.open("wiki.txt", "w")
	file.puts @info
	file.close
	
	file = File.open("login_record.txt", "a")
	username = $credentials[0]
	timenow = Time.now.asctime
	message = "#{username} edited the text at #{timenow} with the changed text being: #{params[:message]}"
	file.puts message
	file.close
	redirect '/'
	
end

#delete the info in Edit-text
delete '/edit/remove' do
	info = "#{params[:message]}"
	@info = info
	file= File.open("wiki.txt", "w")
	file.puts @info
	file.close
	redirect '/'
	
end

#OVERWRITE !!! the info into the wiki2.txt
put '/edit/overwrite' do 
	
	@content = File.read("wiki.txt")
	File.write("wiki2.txt", @content)
	redirect '/'
	#This is another option for overwriting! <-------
	#conten = File.open("wiki.txt", "r")
	#@content = conten.read
	#conten.close
	#file2 = File.open("wiki2.txt", "w")
	#file2.puts @content
	#file2.close
	#redirect '/'
end
#this code is to retrieve the info from wiki2 to wiki!!! 
put '/edit/retrieve' do 
	#Second code for the same option!! <--------
	#@content = File.read("wiki2.txt")
	#File.write("wiki.txt", @content)
	#redirect '/'
	conten = File.open("wiki2.txt", "r")
	@content = conten.read
	conten.close
	file2 = File.open("wiki.txt", "w")
	file2.puts @content
	file2.close
	redirect '/'
end

get '/login' do
	erb :login
end

post '/login' do
	$credentials = [params[:username],params[:password]]
	@Users = User.first(:username => $credentials[0])
	if @Users
		if @Users.password == $credentials[1]
			file = File.open("login_record.txt", "a")   # puts the info about updates login of every user changes in the login record txt.
			username = $credentials[0]
			timenow = Time.now.asctime
			message = "#{username} logged in at #{timenow}"
			file.puts message
			file.close
			redirect '/'
		else
			$credentials =['','']
			redirect '/wrongaccount'
		end
	else
		$credentials = ['','']
		redirect '/wrongaccount'
	end
end


get '/wrongaccount' do
	erb :wrongaccount
end
#------------------------------ This account does not exist
get '/user/:uzer' do
	@Userz = User.first(:username =>params[:uzer])
	if @Userz !=nil
		erb :profile
	else	
		redirect '/noaccount'
	end
end


get '/createaccount' do
	erb :createaccount
end

get '/logout' do
		$credentials = ['', '']
		redirect '/'
	end

put '/user/:uzer' do
	n = User.first(:username => params[:uzer])
	n.edit = params[:edit]? 1:0 
	n.save
	redirect '/' 
end

get '/admincontrols' do
	protected!

	@list2 = User.all :order => :id.desc
	erb :admincontrols
	
end
#-------------------------------------------DELETE USER
delete '/user/delete/:uzer' do
	protected!
	n = User.first(:username => params[:uzer])
	if n.username == "Admin"
		erb :denied
	else
		n.destroy
		@list2 = User.all :order => :id.desc
		erb :admincontrols
	end
end
#-------------------------------------------------> Edit user

get '/user/edit/:uzer' do
  protected!
  @user = User.first(:username => params[:uzer])
  if @user.username == "Admin"
    erb :denied
  else
    erb :useredit 
  end
end

put '/user/update/:uzer' do          #--- change name
  protected!
  @user = User.first(:username => params[:uzer])
  if @user.username == "Admin"
    erb :denied
  else
    @user.username = params[:new_username]
    @user.save
    redirect '/admincontrols'
  end
end
#-------------------------------------Edit User   <-----


#-----------------------Create Account!

post '/createaccount' do
	n = User.new
	n.username = params[:username]
	n.password = params[:password]
	n.date_joined = Time.now
	if n.username == "Admin" and n.password == "123456"
		n.edit = true 
	end
	if n.save == true
		redirect '/accountsuccessful'
	else
		redirect '/wronginfo'
	end
end

#-------------------------Create account in admin controls
post '/admincontrols' do
	protected!
	n = User.new
	n.username = params[:username]
	n.password = params[:password]
	n.date_joined = Time.now
	if n.username == "Admin" and n.password == "123456"
		n.edit = true 
	end
		n.save
	redirect '/admincontrols'
end




get '/accountsuccessful' do         #--- account created successfully
	erb :accountsuccessful
end

get '/wronginfo' do   #---- The account name already exists or you wrote an account name with less than 5 
	erb :wronginfo	
end
	
get '/useredit' do  #--- change user name
	erb :useredit
end

get '/notfound' do #page not found
	erb :notfound
end

get '/noaccount' do  # this account does not exist
	erb :noaccount
end

get '/denied' do   #----- You are not authorised
erb :denied
end


not_found do
	status 404
	redirect '/notfound'
end

helpers do
	def adminonly!
    	redirect '/denied' unless admin?
  	end

  	def admin?
  		authorized? && @Userz.admin == true
 	end
	def protected!
		if authorized?
			return
		end
		redirect '/denied' 
	end
	
	def authorized? 
		if $credentials != nil
			@Userz = User.first(:username => $credentials[0])
			if @Userz
				if @Userz.edit ==true
					return true
				else
					return false
				end
			else
				return false 
			end
		end
	end
end
				
