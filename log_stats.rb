require 'rubygems'
require 'pow'
require 'date'

class Conversation
  attr_accessor :owner, :date, :num_of_messages
  
  def self.chat_filename_to_datetime_string file
    file.split("(")[1][0..-2]
  end
end

@conversations = []

profiles = Pow( Pow("~/Library/Application Support/Adium 2.0/Users") )
profiles.each do |profile| 
  next if profile.class != Pow::Directory
  puts "using profile #{File.basename(profile)}" 
  
  logs = Pow("#{profile}/Logs")
  logs.each do |account| 
    next if account.class != Pow::Directory
    puts "grabbing logs from  #{File.basename(account)}" 
    
    account.each do |contact| 
      next if contact.class != Pow::Directory
      puts "reading conversations with  #{File.basename(contact)}" 
      contact.each do |converation|    
        next if converation.class != Pow::Directory

        filename = File.basename converation
        timestamp = Conversation.chat_filename_to_datetime_string filename
        chat = Conversation.new
        chat.date = Date.parse timestamp
        puts "looking at conversation on #{chat.date.to_s}"
      end    
    end
  end
end
