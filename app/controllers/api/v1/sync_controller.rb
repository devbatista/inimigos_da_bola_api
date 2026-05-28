module Api
  module V1
    class SyncController < ApplicationController
      before_action :authenticate_user!

      def pull
        result = ::Sync::PullChanges.new(
          since: params[:since],
          entities: parsed_entities
        ).call

        if result.success?
          render json: result.data
        else
          render_error(result.code, result.message, :unprocessable_entity)
        end
      end

      def push
        result = ::Sync::ApplyMutation.new(
          user: current_user,
          entity: params[:entity],
          op: push_params[:op],
          record: push_params[:record],
          mutation_id: request.headers["Idempotency-Key"]
        ).call

        if result.success?
          render json: result.data
        else
          render_error(result.code, result.message, http_status_for(result.code))
        end
      end

      private

      def parsed_entities
        return nil if params[:entities].blank?

        params[:entities].to_s.split(",")
      end

      def push_params
        params.permit(:op, record: {}).to_h
      end

      def http_status_for(code)
        case code
        when "SYNC_CONFLICT" then :conflict
        when "FORBIDDEN" then :forbidden
        else :unprocessable_entity
        end
      end
    end
  end
end
