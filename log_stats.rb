require 'rubygems'
require 'pow'
require 'date'
require 'nokogiri'

class Conversation
  attr_accessor :owner, :date, :num_of_messages
  
  def to_s
    "#{owner} - #{date} - #{num_of_messages}"
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
    puts "grabbing logs from  #{File.basename(account)}"  if @debug
    
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
        chat.num_of_messages = doc.css("message").count
        
        puts chat
      end    
    end
  end
end
