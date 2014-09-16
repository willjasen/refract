class TimelineController < ApplicationController
  def index
  end

  def send_hue_card

    setting = set_hue

  	credentials = User.get_credentials(session[:user_id])

  	data = {
      :client_id => ENV["glass_client_id"],
      :client_secret => ENV["glass_client_secret"],
   		:refresh_token => credentials[:refresh_token],
   		:grant_type => "refresh_token"
		}

  	@response = ActiveSupport::JSON.decode(RestClient.post "https://accounts.google.com/o/oauth2/token", data)
  	if @response["access_token"].present?
    	credentials[:access_token] = @response["access_token"]

    	@client = Google::APIClient.new
   		hash = { :access_token => credentials[:access_token], :refresh_token => credentials[:refresh_token] }
    	authorization = Signet::OAuth2::Client.new(hash)
    	@client.authorization = authorization

    	@mirror = @client.discovered_api('mirror', 'v1')
    	
    	insert_subscription( {
      	"kind" => "mirror#subscription",
      	"collection" => "timeline",
      	"userToken" => session[:user_id],
        "verifyToken" => "monkey", #credentials[:verify_token],
      	"operation" => ["UPDATE"],
        "callbackUrl" => ENV['GOOGLE_SUBSCRIPTION_PROXY'] + ENV['hostname'] + '/update_hue'
			})

    	insert_timeline_item( {
        text: setting[:bulb].name + ' bulb',
      	notification: { level: 'DEFAULT' },
      	sourceItemId: 2002,
      	menuItems: [
        	{ 
						action: 'CUSTOM',
						id: 'update',
						values: [
							{ state: "DEFAULT",
								displayName: "Update",
							  iconUrl: 'http://i.imgur.com/DRZUngH.png'
							},
							{ state: "PENDING",
								displayName: "Updating..",
							  iconUrl: 'http://i.imgur.com/DRZUngH.png'
							},
							{ state: "CONFIRMED",
								displayName: "Updated",
							  iconUrl: 'http://i.imgur.com/DRZUngH.png'
							}
						]
					},
        	{ action: 'DELETE' },
					{ action: 'TOGGLE_PINNED' } ]
      	} )

    	if (@result)
        redirect_to(root_path, :notice => "Hue status has been sent to Glass.")
    	else
        redirect_to(root_path, :alert => "Hue status card has failed to send to Glass.")
    	end
    
  		else
    		Rails.logger.debug "No access token"
  	end
	end

  def update_hue

    setting = update_hue_color
    
		credentials = User.get_credentials(session[:user_id])

  	data = {
      :client_id => ENV["glass_client_id"],
      :client_secret => ENV["glass_client_secret"],
   		:refresh_token => credentials[:refresh_token],
   		:grant_type => "refresh_token"
		}

  	@response = ActiveSupport::JSON.decode(RestClient.post "https://accounts.google.com/o/oauth2/token", data)
  	if @response["access_token"].present?
    	credentials[:access_token] = @response["access_token"]

    	@client = Google::APIClient.new
   		hash = { :access_token => credentials[:access_token], :refresh_token => credentials[:refresh_token] }
    	authorization = Signet::OAuth2::Client.new(hash)
    	@client.authorization = authorization

    	@mirror = @client.discovered_api('mirror', 'v1')
    
    	patch_timeline_item( {
        text: setting[:bulb].name + " bulb",
      	notification: { level: 'DEFAULT' },
      	sourceItemId: 1001,
				menuItems: [
        	{ 
						action: 'CUSTOM',
						id: 'update',
						values: [ {
							displayName: "Update",
							iconUrl: 'http://i.imgur.com/DRZUngH.png'
						} ]
					},
        	{ action: 'DELETE' },
					{ action: 'TOGGLE_PINNED' } ]
				} )
  	end
  end

	private
  
  def set_hue
    
    Huey.configure do |config|
      config.uuid = '0123456789abdcef0123456789abcdef'
      config.hue_ip = ENV['bridge_wan_ip']
    end
    
    bulb = Huey::Bulb.find('Kitchen')
    color = Color::CSS['blue'].html
    bulb.update(rgb: color, bri: 254)

    return {bulb: bulb}
    
	end
  
  def update_hue_color
    
    Huey.configure do |config|
      config.uuid = '0123456789abdcef0123456789abcdef'
      config.hue_ip = ENV['bridge_wan_ip']
    end
    
    bulb = Huey::Bulb.find('Kitchen')
    color = Color::CSS['red'].html
    bulb.update(rgb: color, bri: 254)

    return {bulb: bulb}
    
	end


	def insert_timeline_item(timeline_item, attachment_path = nil, content_type = nil)
 		method = @mirror.timeline.insert

		# If a Hash was passed in, create an actual timeline item from it.
 		if timeline_item.kind_of?(Hash)
 			timeline_item = method.request_schema.new(timeline_item)
 		end

 		if attachment_path && content_type
 			media = Google::APIClient::UploadIO.new(attachment_path, content_type)
 			parameters = { 'uploadType' => 'multipart' }
 		else
 			media = nil
 			parameters = nil
 		end

 		@result = @client.execute!(
 			api_method: method,
 			body_object: timeline_item,
 			media: media,
 			parameters: parameters
 		).data
 	end

  def patch_timeline_item(timeline_item, attachment_path = nil, content_type = nil)
		method = @mirror.timeline.update

		# If a Hash was passed in, create an actual timeline item from it.
 		if timeline_item.kind_of?(Hash)
 			timeline_item = method.request_schema.new(timeline_item)
 		end

 		if attachment_path && content_type
 			media = Google::APIClient::UploadIO.new(attachment_path, content_type)
 			parameters = { 'uploadType' => 'multipart' }
 		else
 			media = nil
 			parameters = nil
 		end

 		@result = @client.execute!(
 			api_method: method,
 			body_object: timeline_item,
 			media: media,
 			parameters: parameters
 		).data
	end


	def insert_subscription(timeline_item, attachment_path = nil, content_type = nil)
 		method = @mirror.subscriptions.insert

 		# If a Hash was passed in, create an actual timeline item from it.
 		if timeline_item.kind_of?(Hash)
 			timeline_item = method.request_schema.new(timeline_item)
 		end

 		if attachment_path && content_type
 			media = Google::APIClient::UploadIO.new(attachment_path, content_type)
 			parameters = { 'uploadType' => 'multipart' }
 		else
 			media = nil
 			parameters = nil
 		end

 		@result = @client.execute!(
 			api_method: method,
 			body_object: timeline_item,
 			media: media,
 			parameters: parameters
 		).data
 	end

end
