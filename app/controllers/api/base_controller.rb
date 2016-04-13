module Api
  class BaseController < ApplicationController
    prepend_before_action :doorkeeper_authorize!

    protect_from_forgery with: :null_session, if: proc { |c| c.request.format.json? }

    private

    def authenticate_user!
      if not_signed_in?
        render json: { error: "Authentication required" }, status: 401
      elsif current_user.deactivated?
        render json: { error: "Account deactivated" }, status: 403
      end
    end

    def check_disabled_client
      if client_disabled?
        render json: { error: "Client disabled" }, status: 403
      end
    end

    def auth_errors(exception)
      render json: { error: exception.message }, status: 403
    end
  end
end
