module Web
  class UsersController < ApplicationController
    def index
      @users = policy_scope(User).includes(:position).order(:last_name, :first_name)
      authorize User, request.format.xlsx? ? :export? : :index?

      respond_to do |format|
        format.html
        format.xlsx do
          response.headers["Content-Disposition"] = 'attachment; filename="employees.xlsx"'
        end
      end
    end

    def show
      @user = User.includes(:position).find(params[:id])
      authorize @user
    end
  end
end
