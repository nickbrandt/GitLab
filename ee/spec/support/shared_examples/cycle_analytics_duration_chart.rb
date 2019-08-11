# frozen_string_literal: true

shared_examples 'cycle analytics duration chart endpoint' do
  describe "GET 'duration_chart'" do
    let(:params) do
      {
        stage_name: 'issue',
        cycle_analytics: { start_date: 14 }
      }.merge(request_params)
    end

    around do |example|
      Timecop.freeze { example.run }
    end

    before do
      project.add_maintainer(user)
    end

    context 'when cycle_analytics_duration_chart feature is enabled' do
      before do
        stub_licensed_features(cycle_analytics_duration_chart: true)
        sign_in(user)
      end

      it 'returns empty array when no events found' do
        get :duration_chart, params: params, format: :json

        expect(response).to be_successful
        expect(json_response).to eq([])
      end

      it 'returns duration' do
        issue = create(:issue, created_at: 3.days.ago, project: project)
        issue.metrics.update!(first_associated_with_milestone_at: 2.days.ago)

        get :duration_chart, params: params, format: :json

        expect(response).to be_successful
        expect(json_response.size).to eq(1)

        _, duration = json_response.first
        expect(duration.to_i).to eq(1.day.to_i)
      end

      it 'returns 422 for invalid stage_name' do
        params[:stage_name] = 'invalid_stage_name'

        get :duration_chart, params: params, format: :json

        expect(response).to be_unprocessable
      end
    end

    context 'when cycle_analytics_duration_chart feature is disabled' do
      it 'returns 403' do
        stub_licensed_features(cycle_analytics_duration_chart: false)

        sign_in(user)

        get :duration_chart, params: params, format: :json

        expect(response).to be_forbidden
      end
    end
  end
end
