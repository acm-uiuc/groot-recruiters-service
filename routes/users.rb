# encoding: UTF-8
require_relative '../models/user'

get '/' do
    "This is the groot users service"
end

get '/users' do
    format_response(User.all(order: [ :netid.desc ]), request.accept)
end

get '/users/:netid' do
    user ||= User.first(netid: params[:netid]) || halt(404)
    puts user.inspect
    format_response(user, request.accept)
end

post '/users' do
    string = request.body.read.gsub(/=>/, ":")
    payload = JSON.parse (string || '{"name":"Not Given"}')
    
    return [400, "Missing firstName"] unless payload["firstName"]
    return [400, "Missing netid"] unless payload["netid"]
    return [400, "Missing lastName"] unless payload["lastName"]
    valid = User.is_valid_user?(payload["firstName"], payload["lastName"], payload["netid"])
    puts valid
    user = ""
    if valid
        user = (User.first_or_create(
            {
                netid: payload["netid"]
            },{
                first_name: payload["firstName"],
                last_name: payload["lastName"],
                netid: payload["netid"],
                date_joined: Time.now.getutc
            }
        ))
        puts user.inspect
    end
    status = valid ? 201 : 403
    return [status,format_response(user, request.accept)]
end

put '/users/:netid' do
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
    return [status,format_response(quote, request.accept)]
end

delete '/users/:id' do
    user ||= User.first(netid: params[:netid]) || halt(404)
    halt 500 unless user.destroy
end
