(function () {
  var input = document.getElementById('docs-search');
  if (!input) return;

  var categories = document.querySelectorAll('.docs-category');
  var noResults = document.getElementById('docs-no-results');

  input.addEventListener('input', function () {
    var query = this.value.toLowerCase().trim();
    var anyVisible = false;

    categories.forEach(function (cat) {
      var cards = cat.querySelectorAll('.docs-card');
      var catHasVisible = false;

      cards.forEach(function (card) {
        var title = (card.querySelector('h4') || {}).textContent || '';
        var desc = (card.querySelector('p') || {}).textContent || '';
        var keywords = card.getAttribute('data-keywords') || '';
        var text = (title + ' ' + desc + ' ' + keywords).toLowerCase();

        var match = !query || query.split(/\s+/).every(function (word) {
          return text.indexOf(word) !== -1;
        });

        if (match) {
          card.classList.remove('docs-card-hidden');
          catHasVisible = true;
        } else {
          card.classList.add('docs-card-hidden');
        }
      });

      if (catHasVisible) {
        cat.classList.remove('docs-category-hidden');
        anyVisible = true;
      } else {
        cat.classList.add('docs-category-hidden');
      }
    });

    if (noResults) {
      noResults.style.display = anyVisible ? 'none' : 'block';
    }
  });
})();
