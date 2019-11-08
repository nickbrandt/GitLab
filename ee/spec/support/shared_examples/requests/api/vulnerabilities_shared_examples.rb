# frozen_string_literal: true

shared_examples 'prevents working with vulnerabilities in case of insufficient privileges' do
  context 'with lesser access level than required' do
    it 'responds with 403 Forbidden' do
      project.add_reporter(user)

      subject

      expect(response).to have_gitlab_http_status(403)
    end
  end
end

shared_examples 'responds with "not found" when there is no access to the project' do
  context 'with no project access' do
    let(:project) { create(:project) }

    it 'responds with 404 Not Found' do
      subject

      expect(response).to have_gitlab_http_status(404)
    end
  end

  context 'with unknown project' do
    before do
      project.id = 0
    end

    let(:project) { build(:project) }

    it 'responds with 404 Not Found' do
      subject

      expect(response).to have_gitlab_http_status(404)
    end
  end
end
