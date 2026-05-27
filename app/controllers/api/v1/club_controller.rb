module Api
  module V1
    class ClubController < ApplicationController
      def show
        render json: {
          weekday: ENV.fetch("RACHA_WEEKDAY", "monday"),
          time: ENV.fetch("RACHA_TIME", "20:00"),
          location: ENV.fetch("RACHA_LOCATION", "Arena X"),
          max_players: ENV.fetch("RACHA_MAX_PLAYERS", "20").to_i
        }
      end
    end
  end
end
