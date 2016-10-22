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
  when /new user/i
    user = create_user(message)
  when /help/i
    Bot.deliver(
      recipient: message.sender,
      message: {
        text: 'We\'re working on it' 
      }
    )
  # when /new user/i
  #   user = create_user(message)

  #   Bot.deliver(
  #     recipient: message.sender,
  #     message: {
  #       text: 'success?' 
  #     }
  #   )
  else
    facebook_name = message.text.split
    if facebook_name.length == 2
      found = create_relationship(message.sender["id"], facebook_name[0].downcase, facebook_name[1].downcase)
      if found
        curr_user = User.find_by(facebook_id: message.sender["id"])
        if check_match(message.sender["id"], found)
          Bot.deliver(
            recipient: {id: found},
            message: {
              text: "It's a match with #{curr_user.first_name} #{curr_user.last_name}! I think you guys have some stuff to talk about :) :) :) (P.S. the other received the same message!)"
            }
          )
          Bot.deliver(
            recipient: message.sender,
            message: {
              text: "It's a match with #{facebook_name[0].downcase} #{facebook_name[1].downcase}! I think you guys have some stuff to talk about :) :) :) (P.S. the other received the same message!)"
            }
          )
        else
          Bot.deliver(
            recipient: message.sender,
            message: {
              text: "Logged response! We'll let you know ASAP on developments"
            }
          )
        end
      else
        Bot.deliver(
          recipient: message.sender,
          message: {
            text: "Looks like your crush hasn't used our bot :( \nWe'll let you know if your crush does end up texting us!"
          }
        )
      end
    end
  end
end

Bot.on :postback do |postback|
  case postback.payload
  when /WELCOME_NEW_USER/i
    # if User.find_by(facebook_id: postback.sender["id"]) 
    #   user = User.where(facebook_id: postback.sender["id"])
    # else
    #   user = create_user(postback)
    # end

    user = create_user(message)

    text = "Welcome Lovebird! Text the name of your crush, and we'll try our best!"
    Bot.deliver(
      recipient: postback.sender,
      message: {
        text: text
      }
    ) 
    
  when /CHECK_NEW_USER/i
    crush_id = postback.payload.split('_')[-1]
    user = Relationship.find_by(user_id: postback.sender["id"])
    user.crush_id = crush_id
    user.status = 0;
    user.save
    Bot.deliver(
      recipient: postback.sender,
      message: {
        text: "Yay! We updated your info, we'll get back to you as soon as we hear anything!"
      }
    )

  when /ALL_CURRENT_USER/i
    info = "in progress"
  else
    Bot.deliver(
      recipient: postback.sender,
      message: {
        text: "Couldn't understand that. Try messaging 'help'."
      }
    )
  end

end

Bot.on :delivery do |delivery|
  puts "Delivered message(s) #{delivery.ids}"
end






