require "rails_helper"

RSpec.describe "Skill ratings", type: :request do
  let(:evaluator) { create(:user) }
  let(:evaluated) { create(:user, skill_score: nil) }
  let(:headers) do
    access_token, = Auth::AccessToken.issue_for(evaluator)
    { "Authorization" => "Bearer #{access_token}" }
  end

  describe "POST /api/v1/skill_ratings" do
    it "cria nota e recalcula skill_score do avaliado" do
      post "/api/v1/skill_ratings",
        params: { evaluated_user_id: evaluated.id, score: 80 },
        headers: headers

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body).to include(
        "evaluator_user_id" => evaluator.id,
        "evaluated_user_id" => evaluated.id,
        "score" => 80
      )
      expect(evaluated.reload.skill_score.to_f).to eq(80.0)
    end

    it "calcula media com varias notas" do
      other_evaluator = create(:user)
      create(:skill_rating, evaluator_user: other_evaluator, evaluated_user: evaluated, score: 60)

      post "/api/v1/skill_ratings",
        params: { evaluated_user_id: evaluated.id, score: 100 },
        headers: headers

      expect(response).to have_http_status(:created)
      expect(evaluated.reload.skill_score.to_f).to eq(80.0)
    end

    it "atualiza nota existente apos 1 mes" do
      existing = create(:skill_rating, evaluator_user: evaluator, evaluated_user: evaluated, score: 50)
      existing.update_column(:updated_at, 2.months.ago)

      post "/api/v1/skill_ratings",
        params: { evaluated_user_id: evaluated.id, score: 90 },
        headers: headers

      expect(response).to have_http_status(:created)
      expect(existing.reload.score).to eq(90)
    end

    it "bloqueia reavaliacao antes de 1 mes" do
      create(:skill_rating, evaluator_user: evaluator, evaluated_user: evaluated, score: 50)

      post "/api/v1/skill_ratings",
        params: { evaluated_user_id: evaluated.id, score: 90 },
        headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body).to eq(
        "error" => {
          "code" => "SKILL_RATING_TOO_SOON",
          "message" => "Você só pode reavaliar este jogador após 1 mês."
        }
      )
    end

    it "bloqueia autoavaliacao" do
      post "/api/v1/skill_ratings",
        params: { evaluated_user_id: evaluator.id, score: 80 },
        headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body).to eq(
        "error" => {
          "code" => "SKILL_RATING_SELF_NOT_ALLOWED",
          "message" => "Você não pode avaliar a si mesmo."
        }
      )
    end

    it "rejeita score fora de 0..100" do
      post "/api/v1/skill_ratings",
        params: { evaluated_user_id: evaluated.id, score: 150 },
        headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig("error", "code")).to eq("VALIDATION_ERROR")
    end

    it "retorna erro quando avaliado nao existe" do
      post "/api/v1/skill_ratings",
        params: { evaluated_user_id: SecureRandom.uuid_v7, score: 50 },
        headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig("error", "code")).to eq("VALIDATION_ERROR")
    end

    it "exige autenticacao" do
      post "/api/v1/skill_ratings", params: { evaluated_user_id: evaluated.id, score: 80 }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
