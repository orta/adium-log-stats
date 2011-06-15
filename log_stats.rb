require 'rubygems'
require 'pow'
require 'date'
require 'nokogiri'

class Conversation
  attr_accessor :owner, :recipient, :date, :my_message_count, :their_message_count, :total_message_count
  
  def to_s
    "#{date} - T #{ their_message_count } | Y #{ my_message_count } | #{ total_message_count } ( #{ owner } + #{ recipient })"
  end
  
  def self.chat_filename_to_datetime_string file
    file.split("(")[1][0..-2]
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
        
        recipient_bits = doc.css("message[sender!='#{ account_name }']").first
        chat.recipient = recipient_bits.attr("alias")  if recipient_bits
        
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

  
  
end

most_talked_to_ever

