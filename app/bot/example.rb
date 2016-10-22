require 'facebook/messenger'
require 'functions'
require 'net/http'
require 'json'

# curl -X POST -H "Content-Type: application/json" -d '{
#   "setting_type":"call_to_actions",
#   "thread_state":"new_thread",
#   "call_to_actions":[
#     {
#       "payload":"WELCOME_NEW_USER"
#     }
#   ]
# }' "https://graph.facebook.com/v2.6/me/thread_settings?access_token=EAAEZAbaL0jc0BAJ5JyI1ZCGzmNR9ftC1Ca2DTAqbKTjxdMwuYZAQSzQdsZBTt5WMHWjs8q8qZBJ5jcCYlyZCNOPNxBoWGMLV99ZBa86aJHeRUZAO5jxHgtScuI7goYGfLdCqcQcy6OZBI6fhbDyvFByyZAe2ILBYbXNFmynzUY8m8nfgZDZD"      

Facebook::Messenger.configure do |config|
  config.access_token = ENV['ACCESS_TOKEN']
  config.verify_token = ENV['VERIFY_TOKEN']
end

include Facebook::Messenger

Bot.on :message do |message|
  puts "Received #{message.text} from #{message.sender}"

  case message.text
  when /hello/i
    Bot.deliver(
      recipient: message.sender,
      message: {
        text: 'Hello, human!'
      }
    )
  when /help/i
    Bot.deliver(
      recipient: message.sender,
      message: {
        text: 'We\'re working on it' 
      }
    )
  when /new user/i
    user = create_user(message)

    Bot.deliver(
      recipient: message.sender,
      message: {
        text: 'success?' 
      }
    )
  else
    facebook_name = message.text.split
    if facebook_name.length == 2
      users = User.where(first_name: facebook_name[0].downcase, last_name: facebook_name[1].downcase)
      if not users.empty?
        # users.each do |user|
        # Bot.deliver(
        #   recipient: message.sender,
        #   message: {
        #     attachment: {
        #       type: 'image',
        #       payload:{
        #         url: users.pro_pic
        #       }
        #     }
        #   }
        # ) 
        Bot.deliver(
          recipient: message.sender,
          message: {
            text: users.pro_pic
          }
        )
      else
        Bot.deliver(
          recipient: message.sender,
          message: {
            text: "Couldn't find that person. Text the first and last name of the person."
          }
        )
      end

    end
  end
end

Bot.on :postback do |postback|
  case postback.payload
  when /WELCOME_NEW_USER/i
    if User.find_by(facebook_id: postback.sender["id"]) 
      user = User.where(facebook_id: postback.sender["id"])
    else
      user = create_user(postback)
    end

    text = "Welcome to Hot Ramen, the bot with all the events for Harvard's Opening Days! Created by Ryan Lee '20. \n\nText 'all events' or select the triple line menu button at the botton left and click All Events to start building your schedule!"
    Bot.deliver(
      recipient: postback.sender,
      message: {
        text: text
      }
    ) 
    user = 0

  when "HELP"
    text = "Hello! I'm here to tell you everything going on"
    Bot.deliver(
      recipient: postback.sender,
      message: {
        text: text
      }
    )
    
  else
    Bot.deliver(
      recipient: postback.sender,
      message: {
        text: "Couldn't understand that. Try messaging 'help'. If this is the first time using the bot, text 'new user'"
      }
    )
  end

end

Bot.on :delivery do |delivery|
  puts "Delivered message(s) #{delivery.ids}"
end






