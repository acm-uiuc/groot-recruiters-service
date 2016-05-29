# encoding: UTF-8
require_relative '../models/recruiter'

get '/' do
    "This is the groot recruiters service"
end

get '/recruiters' do
    format_response(Recruiter.all(order: [ :netid.desc ]), request.accept)
end

get '/recruiters/:netid' do
    recruiter ||= Recruiter.first(netid: params[:netid]) || halt(404)
    puts recruiter.inspect
    format_response(recruiter, request.accept)
end

post '/recruiters' do
    payload = JSON.parse(request.body.read)
    return [400, "Missing first_name"] unless payload["first_name"]
    return [400, "Missing netid"] unless payload["netid"]
    return [400, "Missing last_name"] unless payload["last_name"]
    valid = Recruiter.is_valid_recruiter?(payload["first_name"], payload["last_name"], payload["netid"])
    puts valid
    recruiter = ""
    if valid
        recruiter = (Recruiter.first_or_create(
            {
                netid: payload["netid"]
            },{
                first_name: payload["first_name"],
                last_name: payload["last_name"],
                netid: payload["netid"],
                date_joined: Time.now.getutc
            }
        ))
        puts recruiter.inspect
    end
    status = valid ? 201 : 403
    return [status,format_response(quote, request.accept)]
end

put '/recruiters/:netid' do
    payload = JSON.parse(request.body.read)
    return [400, "Missing first_name"] unless payload["first_name"]
    return [400, "Missing netid"] unless payload["netid"]
    return [400, "Missing last_name"] unless payload["last_name"]
    recruiter ||= Recruiter.first(netid: params[:netid]) || halt(404)
    halt 500 unless recruiter.update(
        first_name: payload["first_name"],
        last_name: payload["last_name"],
        netid: payload["netid"],
    )
    return [status,format_response(quote, request.accept)]
end

delete '/recruiters/:id' do
    recruiter ||= Quote.first(netid: params[:netid]) || halt(404)
    halt 500 unless recruiter.destroy
end
