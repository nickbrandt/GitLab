import EC2 from 'aws-sdk/clients/ec2';

export const fetchRegions = () =>
  new Promise((resolve, reject) => {
    const ec2 = new EC2();

    ec2
      .describeRegions()
      .on('success', ({ data: { Regions: regions } }) => {
        const transformedRegions = regions.map(({ RegionName: name }) => ({ name }));

        resolve(transformedRegions);
      })
      .on('error', error => {
        reject(error);
      })
      .send();
  });

export const fetchVpcs = () =>
  new Promise((resolve, reject) => {
    const ec2 = new EC2();

    ec2
      .describeVpcs()
      .on('success', ({ data: { Vpcs: vpcs } }) => {
        const transformedVpcs = vpcs.map(({ VpcId: name }) => ({ name }));

        resolve(transformedVpcs);
      })
      .on('error', error => {
        reject(error);
      })
      .send();
  });

export default () => {};
