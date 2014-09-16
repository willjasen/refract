Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, ENV["glass_client_id"], ENV["glass_client_secret"], {
 access_type: 'offline',
 prompt: 'consent',
 scope: 'https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/glass.timeline',
  redirect_uri: 'http://' + ENV['hostname'] + '/auth/google_oauth2/callback'
 }
end
