# Copyright © 2017, ACM@UIUC
#
# This file is part of the Groot Project.
#
# The Groot Project is open source software, released under the University of
# Illinois/NCSA Open Source License. You should have received a copy of
# this license in a file with the distribution.

module JWTAuth
  def self.decode(env)
    options = { algorithm: 'HS256' }
    bearer = env.fetch('HTTP_RECRUITER_TOKEN', '')
    jwt_secret = Config.load_config('jwt')['secret']

    payload, = JWT.decode bearer, jwt_secret, true, options

    payload.merge!(code: 200)
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
