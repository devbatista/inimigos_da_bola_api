Rails.application.routes.draw do
  devise_for :users,
    path: "api/v1/auth",
    skip: [ :sessions, :passwords ],
    path_names: {
      sign_in: "sign_in",
      sign_out: "sign_out",
      password: "password"
    }

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      namespace :auth do
        post "sign_in", to: "sessions#create"
        delete "sign_out", to: "sessions#destroy"
        post "refresh", to: "sessions#refresh"
        post "password", to: "passwords#create"
        put "password", to: "passwords#update"
      end

      get "users/me", to: "users/me#show"
      post "users/me/fcm_token", to: "users/me#update_fcm_token"
      post "users/invitations", to: "users/invitations#create"
      post "users/accept_invitation", to: "users/invitations#accept"

      get "club", to: "club#show"
      get "weekly_sessions/current", to: "weekly_sessions#current", as: :current_weekly_session
      get "weekly_sessions/:id", to: "weekly_sessions#show", as: :weekly_session
      get "weekly_sessions/:weekly_session_id/attendances", to: "weekly_sessions/attendances#index"
      post "weekly_sessions/:weekly_session_id/attendances", to: "weekly_sessions/attendances#create"
      post "weekly_sessions/:weekly_session_id/guest_attendances", to: "weekly_sessions/guest_attendances#create"
      delete "weekly_sessions/:weekly_session_id/guest_attendances/:id", to: "weekly_sessions/guest_attendances#destroy"
      post "weekly_sessions/:weekly_session_id/stats", to: "weekly_sessions/stats#create"

      post "skill_ratings", to: "skill_ratings#create"

      get "stats/leaderboard", to: "stats#leaderboard"

      get "sync", to: "sync#pull"
      post "sync/:entity", to: "sync#push", constraints: { entity: /[a-z_]+/ }
    end
  end
end
