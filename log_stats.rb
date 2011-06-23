require 'rubygems'
require 'pow'
require 'date'
require 'nokogiri'
require 'set'

class Conversation
  attr_accessor :owner, :recipient, :date, :my_message_count, :their_message_count, :total_message_count, :filepath
  
  def to_s
    "#{date} - T #{ their_message_count } | Y #{ my_message_count } | #{ total_message_count } ( #{ owner } + #{ recipient }) "
  end
  
  def self.chat_filename_to_datetime_string file
    file.split("(")[1][0..-2]
  end
  
  def same_day? conversation
    return false if conversation.date.year != self.date.year
    return false if conversation.date.month != self.date.month
    return false if conversation.date.day != self.date.day
    true
  end
  
  def <=> a
    self.date <=> a.date
  end
  
end

@conversations = []
@debug = false

profiles = Pow( Pow("~/Library/Application Support/Adium 2.0/Users") )
profiles.each do |profile| 
  next if profile.class != Pow::Directory
  puts "using profile #{File.basename(profile)}" if @debug
  
  logs = Pow("#{profile}/Logs")
  logs.each do |account| 
    next if account.class != Pow::Directory
    account_name = File.basename(account).split(".")[1..-1].join(".")
    puts "grabbing logs from  #{account_name}"  if @debug
    
    account.each do |contact| 
      next if contact.class != Pow::Directory
      puts "reading conversations with  #{File.basename(contact)}"  if @debug
      
      contact.each do |conversation|    
        next if conversation.class != Pow::Directory

        filename = File.basename conversation
        timestamp = Conversation.chat_filename_to_datetime_string filename
        chat = Conversation.new
        chat.date = Date.parse timestamp
        puts "looking at conversation on #{chat.date.to_s}" if @debug 
        xml_path = conversation.children[0]
        doc = Nokogiri::XML(open(xml_path))
        chat.my_message_count = doc.css("message[sender='#{ account_name }']").count
        chat.their_message_count = doc.css("message[sender!='#{ account_name }']").count
        chat.total_message_count = doc.css("message").count
        chat.owner = account_name
        chat.filepath = conversation

        recipient_bits = doc.css("message[sender!='#{ account_name }']").first
        if recipient_bits
          if recipient_bits.attr("alias") 
            chat.recipient = recipient_bits.attr("alias")             
          else
            chat.recipient = recipient_bits.attr("sender")
          end
        else
          chat.recipient = File.basename(contact)
        end
      
        puts chat if @debug
        @conversations << chat
      end    
    end
  end
end

def most_talked_to_ever
  @users = {}

  @conversations.each do |chat|
    if @users[chat.recipient]
      @users[chat.recipient] += chat.total_message_count 
    else
      @users[chat.recipient] = chat.total_message_count 
    end
  end
  
  @users =  @users.to_a.sort { |a,b| a.last <=> b.last }
  puts @users  
end

def most_talked_by_day
  @sorted_conversations = @conversations.sort { |a,b| a.date <=> b.date }
  day_top_chatters = []
  
  @sorted_conversations.each do |chat|
    #for each conversation get all chats on the same day
    same_day_chats =  @conversations.select { |compared_chat|
      chat.same_day?(compared_chat)
    }
    top_chat = same_day_chats.sort { |a,b| a.date <=> b.date }.first
    day_top_chatters <<  top_chat
  end
  
  ordered_chatters = SortedSet.new( day_top_chatters.compact.sort{ |a,b| a.date <=> b.date } )
  ordered_chatters.each do |chat|
    puts "#{ chat.date } - #{ chat.recipient } (#{chat.total_message_count})"
  end
end

puts "daily stats-ish"
most_talked_by_day
puts "most talked to stats"
most_talked_to_ever
