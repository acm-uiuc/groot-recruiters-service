module Sinatra
    module JobsRoutes
        def self.registered(app)
            app.get '/jobs' do
                "This is the groot jobs service"
            end
        end
    end
    register JobsRoutes
end