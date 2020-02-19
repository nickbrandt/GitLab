import PipelineTourSuccess from '~/blob/pipeline_tour_success';
import Cookies from 'js-cookie';

describe('PipelineTourSuccess', () => {
  let pipelineSuccess;
  const cookieName = 'some_cookie';

  beforeEach(() => {
    setFixtures(`
      <div class="modal js-success-pipeline-modal" data-commit-cookie="${cookieName}">
      </div>
    `);
    jest.spyOn(Cookies, 'remove');

    pipelineSuccess = new PipelineTourSuccess();
  });

  it('launches the modal', () => {
    pipelineSuccess.disableModalFromRenderingAgain();

    expect(Cookies.remove).toHaveBeenCalledWith(cookieName);
  });
});
