module Auth
  class TokenResponse
    def self.for(user)
      access_token, payload = AccessToken.issue_for(user)
      refresh_token, refresh_token_record = RefreshToken.issue_for(user)

      {
        access_token: access_token,
        access_token_expires_at: Time.at(payload.fetch("exp")).utc.iso8601,
        refresh_token: refresh_token,
        refresh_token_expires_at: refresh_token_record.expires_at.utc.iso8601,
        user: user_payload(user)
      }
    end

    def self.user_payload(user)
      {
        id: user.id,
        email: user.email,
        name: user.name,
        phone: user.phone,
        admin: user.admin,
        player_type: user.player_type,
        skill_score: user.skill_score,
        goalkeeper: user.goalkeeper
      }
    end

    private_class_method :user_payload
  end
end
