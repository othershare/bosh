require 'forwardable'

module Bosh
  module Director
    module Api
      class LocalIdentityProvider
        extend Forwardable

        def initialize(options, _)
          users = options.fetch('users', [])
          @user_manager = Bosh::Director::Api::UserManagerProvider.new.user_manager(users)
        end

        # User management is supported for backwards compatibility
        def_delegators :@user_manager, :supports_api_update?, :create_user, :update_user, :delete_user, :get_user_from_request

        def client_info
          {'type' => 'basic', 'options' => {}}
        end

        def get_user(request_env)
          auth ||= Rack::Auth::Basic::Request.new(request_env)
          raise AuthenticationError unless auth.provided? && auth.basic? && auth.credentials
          if @user_manager.authenticate(*auth.credentials)
            username = auth.credentials.first
            password = auth.credentials[1]
            LocalUser.new(@user_manager, username, password)
          else
            raise AuthenticationError
          end
        end

        class LocalUser

          attr_reader :username

          def initialize(user_manager, username, password)
            @user_manager = user_manager
            @username = username
            @password = password
          end

          def has_access?(_)
            @user_manager.authenticate(@username, @password)
          end
        end
      end
    end
  end
end
