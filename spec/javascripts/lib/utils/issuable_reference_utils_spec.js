import { assembleFullIssuableReference } from '~/lib/utils/issuable_reference_utils';

describe('assembleFullIssuableReference', () => {
  it('should work with only issue number reference', () => {
    expect(assembleFullIssuableReference('#111', 'foo', 'bar')).toEqual('foo/bar#111');
  });
  it('should work with project and issue number reference', () => {
    expect(assembleFullIssuableReference('qux#111', 'foo', 'bar')).toEqual('foo/qux#111');
  });
  it('should work with full reference', () => {
    expect(assembleFullIssuableReference('foo/garply#111', 'foo', 'bar')).toEqual('foo/garply#111');
  });
  it('should work with sub-groups', () => {
    expect(assembleFullIssuableReference('some/with/sub/groups/other#111', 'foo', 'bar')).toEqual('some/other#111');
  });
  it('does not mangle other group references', () => {
    expect(assembleFullIssuableReference('some/other#111', 'foo', 'bar')).toEqual('some/other#111');
  });
  it('does not mangle other group even with partial match', () => {
    expect(assembleFullIssuableReference('bar/baz/fido#111', 'foo/bar/baz', 'garply')).toEqual('bar/baz/fido#111');
  });
});
