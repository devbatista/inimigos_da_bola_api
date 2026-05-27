module WeeklySessions
  class CreateCurrentJob < ApplicationJob
    queue_as :default

    def perform
      WeeklySessions::CreateCurrent.new.call
    end
  end
end
