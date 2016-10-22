# curl -X POST -H "Content-Type: application/json" -d '{
#   "setting_type" : "call_to_actions",
#   "thread_state" : "existing_thread",
#   "call_to_actions":[
#     {
#       "type":"postback",
#       "title":"All Events",
#       "payload":"MORE_ALL_EVENTS_0"
#     },
#     {
#       "type":"postback",
#       "title":"My Events",
#       "payload":"MY_EVENTS"
#     },
#     {
#       "type":"postback",
#       "title":"Help",
#       "payload":"HELP"
#     }
#   ]
# }' "https://graph.facebook.com/v2.6/me/thread_settings?access_token=EAANT2k7GtasBADWMzmyTUyc59MQZCxpJWfQWFTvwsjvF3rrU97nniUD8Ov93LzDdHFtNleEMHg8AvuvGU2vf4y3FosPvI9cQ1ID1rMe52QZCZAMywQ8ZAhZBltzXwcSk0MeuEBUqfLYT16aM0LsOG8QCf0okD7vrCbPNnVqzhYwZDZD"    
require 'json'

def create_user(message)
	access = ENV['ACCESS_TOKEN']
	user_id = message.sender["id"]
	output =`curl -X GET https://graph.facebook.com/v2.6/#{user_id}?access_token=#{access}`
	info = JSON.parse(output)
	if User.find_by(facebook_id: user_id)
		User.find_by(facebook_id: user_id).destroy
	end

	User.create(facebook_id: user_id, first_name: info["first_name"].downcase, last_name: info["last_name"].downcase, pro_pic: info["profile_pic"]) 

	users = Relationship.where(first_name: info["first_name"].downcase, last_name: info["last_name"].downcase, status: 1)
	
	if not users.empty?
		users.each do |user|
			# Bot.deliver(
		 #        recipient: {id: user.user_id},
		 #        message: {
		 #          	attachment: {
			#             type: 'template',
			#             payload:{
			#             	template_type:"generic",
			#             	elements:[
			#             		{
			#             			title: "Is this your crush?",
			#             			item_url:"https://www.harvard.edu",
			#             			image_url: info["profile_pic"],
			#             			subtitle: "thread_settings",
			#             			buttons: [
			#             				{
			#             					type: "postback",
			#             					title: "Yes!",
			#             					#payload: "CHECK_NEW_USER_#{info["first_name"].downcase}_#{info["last_name"].downcase}_#{user_id}"
			#             					payload: "CHECK_NEW_USER_#{user_id}"
			#             				}
			#             			]
			#             		}
			#             	]
		 #            	}
		 #          	}
		 #        }
	  #   	)
		  	Bot.deliver(
	            recipient: {id: user.user_id},
	            message: {
	              text: "asdf"
	            }
	        )	 
		end
	end
end

def create_relationship(user_id, crush_first_name, crush_last_name)
	if Relationship.find_by(user_id: user_id)
		Relationship.find_by(user_id: user_id)
	end

	users = User.find_by(first_name: crush_first_name, last_name: crush_last_name)
	
	if users
	    # users.each do |user|
	    #   Bot.deliver(
	    #     recipient: message.sender,
	    #     message: {
	    #       attachment: {
	    #         type: 'image',
	    #         payload:{
	    #           url: users[0].pro_pic
	    #         }
	    #       }
	    #     }
	    #   )
	    # end 
	   	Relationship.create(user_id: user_id, crush_id: users[0].facebook_id, status: 0, first_name: crush_first_name, last_name: crush_last_name)
		return users[0].facebook_id
	else
		Relationship.create(user_id: user_id, crush_id: nil, status: 1, first_name: crush_first_name, last_name: crush_last_name)
		return false
	end
end

def check_match(user_id, crush_id)
	a = Relationship.where(user_id: user_id)
	b = Relationship.where(user_id: crush_id)
	puts "user_id: #{user_id}, crush_id: #{crush_id}, a.crush_id: #{a.crush_id}, b.crush_id: #{b.crush_id}"
	if a.empty? == false and b.empty? == false and a.crush_id == crush_id and b.crush_id == user_id 
		return true
	else
		return false
	end
end



