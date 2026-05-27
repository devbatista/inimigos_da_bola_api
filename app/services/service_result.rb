class ServiceResult
  attr_reader :data, :code, :message

  def self.success(data = nil)
    new(success: true, data: data)
  end

  def self.failure(code, message)
    new(success: false, code: code, message: message)
  end

  def initialize(success:, data: nil, code: nil, message: nil)
    @success = success
    @data = data
    @code = code
    @message = message
  end

  def success?
    @success
  end

  def failure?
    !success?
  end
end
