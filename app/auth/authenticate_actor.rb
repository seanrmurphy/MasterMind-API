class AuthenticateActor
  def initialize(code)
    @code = code
  end

  # Service entry point
  def call
    client_id = 'f856da058c20414db0e946d234a5b9b1'
    secret_id = '08eaae80ae544d66ba858de71adb7421'
    encodedData = 'Basic ' + Base64.strict_encode64(client_id + ':' + secret_id)
    #logger.debug 'Encoded data: ' + encodedData
    client = OAuth2::Client.new(
        client_id,
        secret_id,
        :authorize_url => "/oauth2/authorize",
        :token_url => "/oauth2/token",
        :site => "https://account.lab.fiware.org"
    )
    token = client.auth_code.get_token(code, :redirect_uri => 'http://localhost:3000/auth/login', :headers => {'Authorization' => encodedData})
    #logger.debug "token " + token.token
    response = token.get('/user', :params => { 'access_token' => token.token })
    email = JSON.parse(response.body)["email"]
    fullname = JSON.parse(response.body)["displayName"]
    actor = Actor.find_by(email: email)
    if actor.nil?
      actor = Actor.create!(email: email, fullname: fullname)
    end
    return JsonWebToken.encode(actor_id: actor.id)
  rescue ActiveRecord::RecordNotFound => e
    raise(ExceptionHandler::AuthenticationError, Message.invalid_credentials)
  rescue OAuth2::Error => e
    raise(ExceptionHandler::AuthenticationError, Message.invalid_credentials)
  end

  private

  attr_reader :code

end
