module Web
  class UsersController < ApplicationController
    def index
      @users = policy_scope(User).includes(:position).order(:last_name, :first_name)
      authorize User
    end

    def show
      @user = User.includes(:position).find(params[:id])
      authorize @user
    end
  end
end
