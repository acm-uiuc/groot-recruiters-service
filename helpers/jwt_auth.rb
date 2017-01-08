require 'pry'

module JWTAuth
  def self.decode(env)
    begin
      options = { algorithm: 'HS256' }
      bearer = env.fetch('HTTP_RECRUITER_TOKEN', '')
      jwt_secret = Config.load_config("jwt")["secret"]

      payload, header = JWT.decode bearer, jwt_secret, true, options

      payload.merge!({ code: 200})
    rescue JWT::DecodeError
      { code: 401, error: 'A token must be passed.' }
    rescue JWT::ExpiredSignature
      { code: 403, error: 'The token has expired.' }
    rescue JWT::InvalidIssuerError
      { code: 403, error: 'The token does not have a valid issuer.' }
    rescue JWT::InvalidIatError
      { code: 403, error: 'The token does not have a valid "issued at" time.' }
    end
  end
end