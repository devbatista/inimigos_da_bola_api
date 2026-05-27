module Auth
  class AccessToken
    def self.issue_for(user)
      token, payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
      [ token, payload ]
    end
  end
end
