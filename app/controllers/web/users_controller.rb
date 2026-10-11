module Web
  class UsersController < ApplicationController
    def index
      @users = policy_scope(User).includes(:position).order(:last_name, :first_name)
      authorize User, request.format.xlsx? ? :export? : :index?

      respond_to do |format|
        format.html do
          if policy([ :admin, User ]).index?
            redirect_to admin_users_path
          else
            @employees_count = Position.sum(:users_count)
          end
        end
        format.xlsx do
          response.headers["Content-Disposition"] = 'attachment; filename="employees.xlsx"'
        end
      end
    end

    def show
      @user = User.includes(:position).find(params[:id])
      authorize @user
      redirect_to admin_user_path(@user) if request.format.html? && policy([ :admin, @user ]).show?
    end
  end
end
