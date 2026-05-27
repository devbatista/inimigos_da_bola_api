Rails.application.routes.draw do
  devise_for :users,
    path: "api/v1/auth",
    skip: [ :sessions ],
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
      end

      get "club", to: "club#show"
      get "weekly_sessions/current", to: "weekly_sessions#current", as: :current_weekly_session
      get "weekly_sessions/:id", to: "weekly_sessions#show", as: :weekly_session
    end
  end
end
