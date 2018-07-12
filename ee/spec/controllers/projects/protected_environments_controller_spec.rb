require 'spec_helper'

describe Projects::ProtectedEnvironmentsController do
  let(:project) { create(:project) }
  let(:current_user) { create(:user) }
  let(:master_access) { Gitlab::Access::MASTER }

  before do
    sign_in(current_user)
  end

  describe '#POST create' do
    subject do
      post :create,
        namespace_id: project.namespace.to_param,
        project_id: project.to_param,
        protected_environment: params
    end

    context 'with valid access and params' do
     let(:params) do
        attributes_for(:protected_environment, 
                       deploy_access_levels_attributes: [{ access_level: master_access }])
      end 

      before do
        project.add_master(current_user)
      end

      it 'should create a new ProtectedEnvironment' do
        expect do
          subject 
        end.to change(ProtectedEnvironment, :count).by(1)
      end

      it 'should set a flash' do
        subject

        expect(controller).to set_flash[:notice].to(/environment has been protected/)
      end

      it 'should redirect to CI/CD settings' do
        subject 

        expect(response).to redirect_to project_settings_ci_cd_path(project)
      end
    end

    context 'with valid access and invalid params' do
      before do
        project.add_master(current_user)
      end

      let(:params) do
        attributes_for(:protected_environment, 
                       name: '',
                       deploy_access_levels_attributes: [{ access_level: master_access }])
      end


      it 'should not create a new ProtectedEnvironment' do
        expect do
          subject
        end.not_to change(ProtectedEnvironment, :count)
      end

      it 'should redirect to CI/CD settings' do
        subject

        expect(response).to redirect_to project_settings_ci_cd_path(project)
      end
    end

    context 'with invalid access' do
      let(:params) do
        attributes_for(:protected_environment, 
                       deploy_access_levels_attributes: [{ access_level: master_access }])
      end

      before do
        project.add_developer(current_user)
      end

      it 'should render 404' do
        subject

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end
end
