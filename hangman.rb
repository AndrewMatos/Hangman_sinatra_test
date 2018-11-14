require 'sinatra'
require 'sinatra/reloader' if development?

set :public_folder, File.dirname(__FILE__)


  enable :sessions
  #set :session_secret, "secret"


  get '/' do
    @session = session
  	@name = nil
    erb :index
  end

 post '/game' do
   if params[:first_turn] == "false"
      if params[:letter] == "exit"
      	redirect to('/game/exit')
      else
   	  session["game"].checkletter(params[:letter])
   	  end

   	  if session["game"].turn ==10
        redirect to('/game/loser')
      elsif session["game"].win?
        redirect to('/game/winner')
      end
   end	
  
   if params[:first_turn] == "true"
   	session["name"] = params[:name]
 	gm = Game.new(params[:load?])
 	session["game"]= gm
   end
   @name = session[:name]
   puts params
   #puts session["game"].table.playerstatus
 	@word = session["game"].table.spaceword
 	@hang = session["game"].table.playerstatus
 	@letters = session["game"].table.letters_used
 	#@cheat = session["game"].pc.word
 	erb :game
 end

 get '/game/loser' do
 	erb :loser
 end

 get '/game/winner' do
 	erb :winner
 end

 get "/game/exit" do
 	erb :exit 
 end

 post "/save" do
 	if params[:save] == "true"
 		session["game"].save_game
 	end
 	redirect to('/')
 end
	



class Game

	attr_accessor :pc, :table, :turn

	def initialize(loadg)
	  @pc = Pc.new
	  @table =Table.new(@pc.word)
	  @turn=0
	  if loadg =="load"
	  load_game
      end
	end

    def checkletter(choice)
    	choice = choice.downcase
    
        	  if @pc.word.include?(choice)
        	  	  @pc.word.each_with_index do |element, index|
	        	  	 	if element == choice
	        	  	 		@table.numberOfWords[index]=choice
	        	  	 	end
        	  	  end
        	  	  if @table.letterused.include?(choice) == false
        	  	    @table.letterused.push(choice)
        	  	  end
        	  else
	              @table.playerstatus.unshift(@table.hangdummy[@turn])
	              if @table.letterused.include?(choice)== false
	        	  	 @table.letterused.push(choice)
	        	  end
	              @turn=@turn + 1
        	  end
    end

	def load_game
		f=File.open("savedparty.txt","r")
		pcj=f.gets
		@pc.load(JSON.parse(pcj))
	    turnj=f.gets
	    @turn= JSON.parse(turnj)
	    tablej=f.gets
	    @table.load(JSON.parse(tablej))		
		f.close
	end

	def win?
		n = true
		@pc.word.each_with_index do |element, index|
			if element != @table.numberOfWords[index]
				n = false
			end
		end
	return n
	end

	def save_game
         
          f= File.new("savedparty.txt","w")
          f.puts @pc.to_json
          f.puts @turn.to_json
          f.puts @table.to_json
          f.close                  	
	end

	class Table
		attr_accessor :numberOfWords, :hangdummy, :playerstatus, :letterused, :turn


		def initialize (word)
			@numberOfWords=("_"*word.length).split("")
			@hangdummy=["\|________\|","\|            \|","\|   \|_____","_\|_","  \|   / \\","  \|    \|","  \|   /\|\\","  \|    o","  \|    \|","   ____"]
			@hangdummy = @hangdummy.map { |element| element.gsub(" ", "&nbsp;") }
		    @playerstatus=[]
		    @letterused=[]
		end

		 def to_json
		 	{"numberOfWords"=>@numberOfWords, "hangdummy"=>@hangdummy, "playerstatus"=>@playerstatus,"letterused"=>@letterused}.to_json
		 end

		 def load(hash) 
		 	@numberOfWords=hash["numberOfWords"]
		 	@hangdummy=hash["hangdummy"]
           @playerstatus=hash["playerstatus"]
            @letterused=hash["letterused"]
		 end

		 def spaceword
		 	return "\n\r #{@numberOfWords.join(" ")}"
		 end

		 def letters_used
		 	return "letters used: #{@letterused.join(" ")}"
		 end


    end 

	class Pc
		attr_reader :word

		def initialize
			m = search_word
			@word = m
		end

		 def to_json
		 	{"word"=>@word}.to_json
		 end

		 def load(hash)
		 	@word=hash["word"]
		 end

	     def search_word
	        words=File.readlines("Dictionary.txt")
	        words= words.select do |element|
	        	element = element.chomp!
	        	element.length >= 5 && element.length <=12
	        end
	        
	        word = words[rand(words.length)]
	        word = word.downcase.split("")	        
	        return word	        
	     end
	end

end