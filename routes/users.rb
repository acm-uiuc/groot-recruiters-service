# encoding: UTF-8
module Sinatra
    module UsersRoutes
        def self.registered(app)
            app.get '/' do
                "This is the groot users service"
            end

            app.get '/users' do
                ResponseFormat.format_response(User.all(order: [ :netid.desc ]), request.accept)
            end

            app.get '/users/:netid' do
                user ||= User.first(netid: params[:netid]) || halt(404)
                puts user.inspect
                ResponseFormat.format_response(user, request.accept)
            end

            app.put '/users/:netid' do
                payload = JSON.parse(request.body.read)
                return [400, "Missing first_name"] unless payload["first_name"]
                return [400, "Missing netid"] unless payload["netid"]
                return [400, "Missing last_name"] unless payload["last_name"]
                user ||= User.first(netid: params[:netid]) || halt(404)
                halt 500 unless user.update(
                    first_name: payload["first_name"],
                    last_name: payload["last_name"],
                    netid: payload["netid"],
                )
                return [status, ResponseFormat.format_response(quote, request.accept)]
            end

            app.delete '/users/:id' do
                user ||= User.first(netid: params[:netid]) || halt(404)
                
                # Delete Resume from S3 if it exists
                AWS.delete_resume(user.netid)
                
                halt 500 unless user.destroy
            end
        end
    end
    register UsersRoutes
end
