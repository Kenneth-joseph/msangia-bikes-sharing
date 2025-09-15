class AddOtpFieldsToUser < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :otp_secret, :string
    add_column :users, :otp_backup_codes, :text
    add_column :users, :otp_required_for_login, :boolean, default: false
    add_column :users, :otp_enabled, :boolean, default: false
  end
end
