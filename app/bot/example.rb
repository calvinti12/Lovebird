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
  else
    facebook_name = message.text.split
    if facebook_name.length == 2
      first_name = facebook_name[0].downcase
      last_name = facebook_name[1].downcase
      users = User.where(first_name: first_name, last_name: last_name).limit(1)
      if users.any?
        Bot.deliver(
            recipient: message.sender,
            message: {
              attachment: {
                type: 'image',
                payload:{
                  url: users[0].pro_pic
                }
              }
            }
        ) 
        Bot.deliver(
          recipient: message.sender,
          message: {
            attachment:{
              type: 'template',
              payload: {
                template_type: 'button',
                text: "Is this your crush?",
                buttons: [
                  { type: 'postback', title: 'Yes!', payload: 'NEW_RELATIONSHIP_' + first_name + "_" + last_name + "_" + users[0].crush_id },
                  { type: 'postback', title: 'Nah', payload: 'ALL_CURRENT_USER_' + first_name + "_" + last_name + "_" + "1"}
                ]
              }
            }
          }
        ) 
      else
        Bot.deliver(
          recipient: message.sender,
          message: {
            text: "Looks like your crush hasn't used our bot :( \nWe'll keep the name on record and let you know if your crush does end up texting us!"
          }
        )
        Relationship.create(user_id: message.sender["id"], crush_id: nil, status: 1, first_name: first_name, last_name: last_name)

      end
    else
      Bot.deliver(
        recipient: message.sender,
        message: {
          text: "Sorry, we couldn't catch that. We need just the first and last name of your crush!"
        }
      )
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

    user = create_user(postback)

    text = "Welcome Lovebird! Text the first and last name of your crush and we'll connect you if we hear anything back!"
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

  when /NOPE/i
    Bot.deliver(
      recipient: postback.sender,
      message: {
        text: "Oops, we'll keep searching!"
      }
    )

  when /ALL_CURRENT_USER/i
    crush_num = postback.payload.split('_')[-1].to_i
    first_name = postback.payload.split('_')[-3]
    last_name = postback.payload.split('_')[-2]
    users = User.where(first_name: first_name, last_name: last_name).limit(1).offset(crush_num)
    
    if users.any?
      Bot.deliver(
          recipient: postback.sender,
          message: {
            attachment: {
              type: 'image',
              payload:{
                url: users[0].pro_pic
              }
            }
          }
      ) 
      Bot.deliver(
        recipient: postback.sender,
        message: {
          attachment:{
            type: 'template',
            payload: {
              template_type: 'button',
              text: "Is this your crush?",
              buttons: [
                { type: 'postback', title: 'Yes!', payload: 'NEW_RELATIONSHIP_' + first_name + "_" + last_name + "_" + users[0].facebook_id },
                { type: 'postback', title: 'Nah', payload: 'ALL_CURRENT_USER_' + first_name + "_" + last_name + "_" + (crush_num+1).to_s}
              ]
            }
          }
        }
      ) 
    else
      Bot.deliver(
        recipient: postback.sender,
        message: {
          text: "Looks like your crush hasn't used our bot :( \nWe'll keep the name on record and let you know if your crush does end up texting us!"
        }
      )
      create_relationship(postback.sender["id"], nil, first_name, last_name)
    end

  when /NEW_RELATIONSHIP/i
    crush_id = postback.payload.split('_')[-1]
    first_name = postback.payload.split('_')[-3]
    last_name = postback.payload.split('_')[-2]
    create_relationship(postback.sender["id"], crush_id, first_name, last_name)
    curr_user = User.find_by(facebook_id: postback.sender["id"])
    if check_match(postback.sender["id"], crush_id)
      Bot.deliver(
        recipient: {id: crush_id},
        message: {
          text: "It's a match with #{curr_user.first_name} #{curr_user.last_name}! I think you guys have some stuff to talk about :) :) :) (P.S. the other received the same message!)"
        }
      )
      Bot.deliver(
        recipient: postback.sender,
        message: {
          text: "It's a match with #{first_name} #{last_name}! I think you guys have some stuff to talk about :) :) :) (P.S. the other received the same message!)"
        }
      )
    else
      Bot.deliver(
        recipient: postback.sender,
        message: {
          text: "Logged response! We'll let you know ASAP on developments with #{facebook_name[0].downcase} #{facebook_name[1].downcase}"
        }
      )
    end

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






