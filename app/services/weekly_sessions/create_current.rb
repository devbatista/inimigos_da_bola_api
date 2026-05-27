module WeeklySessions
  class CreateCurrent
    WEEKDAYS = {
      "monday" => 1,
      "tuesday" => 2,
      "wednesday" => 3,
      "thursday" => 4,
      "friday" => 5,
      "saturday" => 6,
      "sunday" => 0
    }.freeze

    def call
      weekly_session = WeeklySession.active
        .where(scheduled_at: scheduled_range)
        .first_or_create!(scheduled_at: scheduled_at, max_players: max_players, status: :scheduled)

      ServiceResult.success(weekly_session)
    rescue KeyError
      ServiceResult.failure("VALIDATION_ERROR", "Dia do racha invalido.")
    rescue ArgumentError
      ServiceResult.failure("VALIDATION_ERROR", "Horario do racha invalido.")
    end

    private

    def scheduled_at
      @scheduled_at ||= Time.zone.parse("#{scheduled_date} #{racha_time}").utc
    end

    def scheduled_range
      scheduled_at.beginning_of_day..scheduled_at.end_of_day
    end

    def scheduled_date
      today = Time.zone.today
      start_of_week = today.beginning_of_week(:monday)
      start_of_week + weekday_offset.days
    end

    def weekday_offset
      wday = WEEKDAYS.fetch(racha_weekday)
      wday.zero? ? 6 : wday - 1
    end

    def racha_weekday
      ENV.fetch("RACHA_WEEKDAY", "monday").downcase
    end

    def racha_time
      ENV.fetch("RACHA_TIME", "20:00")
    end

    def max_players
      ENV.fetch("RACHA_MAX_PLAYERS", "20").to_i
    end
  end
end
