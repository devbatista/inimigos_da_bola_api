module SyncRecord
  extend ActiveSupport::Concern

  included do
    self.locking_column = :version

    before_validation :assign_uuid_v7, on: :create
    scope :active, -> { where(deleted_at: nil) }
    scope :deleted, -> { where.not(deleted_at: nil) }
  end

  def soft_delete!
    update!(deleted_at: Time.current)
  end

  private

  def assign_uuid_v7
    self.id ||= SecureRandom.uuid_v7
  end
end
