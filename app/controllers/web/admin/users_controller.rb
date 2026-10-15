module Web
  module Admin
    class UsersController < Web::ApplicationController
      before_action :set_user, only: %i[show edit update destroy]

      def index
        authorize [ :admin, User ]
        load_users
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
        if turbo_frame_request?
          load_users
          flash.now[:notice] = t("flash.users.created")
          render :create, formats: :turbo_stream
        else
          redirect_to admin_user_path(@user), notice: t("flash.users.created")
        end
      rescue ActiveRecord::RecordInvalid
        render :new, formats: :html, status: :unprocessable_entity
      end

      def edit
        authorize [ :admin, @user ]
      end

      def update
        authorize [ :admin, @user ]
        authorize [ :admin, @user ], :change_role? if submitted_role != @user.role_name

        @user.save_with_role!(user_params, role: submitted_role)
        if turbo_frame_request?
          load_users
          flash.now[:notice] = t("flash.users.updated")
          render :update, formats: :turbo_stream
        else
          redirect_to admin_user_path(@user), notice: t("flash.users.updated")
        end
      rescue ActiveRecord::RecordInvalid
        render :edit, formats: :html, status: :unprocessable_entity
      end

      def destroy
        authorize [ :admin, @user ]
        @user.destroy_with_role_safety!
        respond_to do |format|
          format.html { redirect_to admin_users_path, notice: t("flash.users.deleted") }
          format.turbo_stream do
            @employees_count = Position.sum(:users_count)
            flash.now[:notice] = t("flash.users.deleted")
          end
        end
      rescue ActiveRecord::RecordInvalid => error
        redirect_to admin_user_path(error.record), alert: error.record.errors.full_messages.to_sentence
      end

      private

      def set_user
        @user = User.includes(:position, :roles).find(params[:id])
      end

      def load_users
        @users = policy_scope([ :admin, User ]).includes(:position, :roles).order(:last_name, :first_name)
        @employees_count = Position.sum(:users_count)
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
