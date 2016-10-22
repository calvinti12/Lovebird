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
end

