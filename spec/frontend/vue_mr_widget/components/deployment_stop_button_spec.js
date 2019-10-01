describe('Deployment Stop Button', () => {
  let wrapper;

  const factory = (options = {}) => {
    const localVue = createLocalVue();

    wrapper = mount(localVue.extend(DeploymentComponent), {
      localVue,
      ...options,
    });
  };

  beforeEach(() => {
    factory({
      propsData: {
        deployment: deploymentMockData,
        showMetrics: false
      }
    })
  });

  afterEach(() => {
    wrapper.destroy();
  });

  // it displays the icon
  // is there a way to test the tooltip? is it worth it?
  // move over the mocking and spying — maybe make sure I want to keep the old implementation
  // or align it with new ones?


});

// TODO: Convert to Jest
// describe('stopEnvironment', () => {
//   const url = '/foo/bar';
//   const returnPromise = () =>
//     new Promise(resolve => {
//       resolve({
//         data: {
//           redirect_url: url,
//         },
//       });
//     });
//   const mockStopEnvironment = () => {
//     vm.stopEnvironment(deploymentMockData);
//     return vm;
//   };
//
//   it('should show a confirm dialog and call service.stopEnvironment when confirmed', done => {
//     spyOn(window, 'confirm').and.returnValue(true);
//     spyOn(MRWidgetService, 'stopEnvironment').and.returnValue(returnPromise(true));
//     const visitUrl = spyOnDependency(deploymentComponent, 'visitUrl').and.returnValue(true);
//     vm = mockStopEnvironment();
//
//     expect(window.confirm).toHaveBeenCalled();
//     expect(MRWidgetService.stopEnvironment).toHaveBeenCalledWith(deploymentMockData.stop_url);
//     setTimeout(() => {
//       expect(visitUrl).toHaveBeenCalledWith(url);
//       done();
//     }, 333);
//   });
//
//   it('should show a confirm dialog but should not work if the dialog is rejected', () => {
//     spyOn(window, 'confirm').and.returnValue(false);
//     spyOn(MRWidgetService, 'stopEnvironment').and.returnValue(returnPromise(false));
//     vm = mockStopEnvironment();
//
//     expect(window.confirm).toHaveBeenCalled();
//     expect(MRWidgetService.stopEnvironment).not.toHaveBeenCalled();
//   });
// });
