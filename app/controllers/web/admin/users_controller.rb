module Web
  module Admin
    class UsersController < Web::ApplicationController
      before_action :set_user, only: %i[show edit update destroy]

      def index
        @users = policy_scope([ :admin, User ]).includes(:position, :roles).order(:last_name, :first_name)
        authorize [ :admin, User ]
      end

      def show
        authorize [ :admin, @user ]
      end

      def new
        @user = User.new(role_name: "employee")
        authorize [ :admin, @user ]
      end

      def create
        @user = User.new
        authorize [ :admin, @user ]
        @user.assign_attributes(user_params)

        @user.save_with_role!(role: submitted_role)
        redirect_to admin_user_path(@user), notice: "User created"
      rescue ActiveRecord::RecordInvalid
        render :new, status: :unprocessable_entity
      end

      def edit
        authorize [ :admin, @user ]
      end

      def update
        authorize [ :admin, @user ]
        authorize [ :admin, @user ], :change_role? if submitted_role != @user.role_name

        @user.save_with_role!(user_params, role: submitted_role)
        redirect_to admin_user_path(@user), notice: "User updated"
      rescue ActiveRecord::RecordInvalid
        render :edit, status: :unprocessable_entity
      end

      def destroy
        authorize [ :admin, @user ]
        @user.destroy_with_role_safety!
        redirect_to admin_users_path, notice: "User deleted"
      rescue ActiveRecord::RecordInvalid => error
        redirect_to admin_user_path(error.record), alert: error.record.errors.full_messages.to_sentence
      end

      private

      def set_user
        @user = User.includes(:position, :roles).find(params[:id])
      end

      def user_params
        attributes = params.require(:user).permit(policy([ :admin, @user ]).permitted_attributes)
        return attributes unless @user.persisted? && attributes[:password].blank?

        attributes.except(:password, :password_confirmation)
      end

      def submitted_role
        params.require(:user).permit(:role_name).fetch(:role_name, "")
      end
    end
  end
end
