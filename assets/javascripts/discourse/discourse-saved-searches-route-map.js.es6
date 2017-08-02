export default {
  resource: 'user.preferences',
  map() {
    this.route('savedSearches', { path: '/saved-searches' });
  }
};
