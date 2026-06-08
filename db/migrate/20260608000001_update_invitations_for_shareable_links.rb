class UpdateInvitationsForShareableLinks < ActiveRecord::Migration[8.1]
  def change
    change_column_null :users, :email, true
    add_column :users, :invitation_expires_at, :datetime
  end
end
