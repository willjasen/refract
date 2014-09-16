class User < ActiveRecord::Base
  validates :email, :refresh_token, :verify_token, :oauth_token, presence: true

  def self.get_credentials(user_id)
    user = User.find(user_id)
    
   if user
     begin
      user.verify_token = SecureRandom.hex
     end while user.class.exists?(verify_token: user.verify_token)
     # Get the token and refresh as a hash
     hash = {email: user.email, verify_token: user.verify_token, refresh_token: user.refresh_token}
   end
 end  
end
