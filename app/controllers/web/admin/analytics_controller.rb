module Web
  module Admin
    class AnalyticsController < Web::ApplicationController
      def show
        authorize [ :admin, :analytics ], :show?

        @positions = Position.order(:name).to_a
        @recent_employees = @positions.index_with do |position|
          position.users.order(hired_on: :desc, id: :desc).limit(5).to_a
        end
      end
    end
  end
end
