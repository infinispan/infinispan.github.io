(function() {
   var searchInput = document.getElementById('guides-search-input');
   var grid = document.getElementById('guides-grid');
   var empty = document.getElementById('guides-empty');
   var cards = grid.querySelectorAll('.guide-card');
   var sidebarCheckboxes = document.querySelectorAll('.sidebar-checkbox input[type="checkbox"]');
   var topicCheckboxes = document.querySelectorAll('.topic-option input[type="checkbox"]');
   var allCheckboxes = document.querySelectorAll('input[data-filter-type]');
   var languageTabs = document.querySelectorAll('.language-tab');
   var activeLanguage = 'all';

   var selectInput = document.getElementById('topic-select-input');
   var dropdown = document.getElementById('topic-select-dropdown');
   var tagsContainer = document.getElementById('topic-tags');

   selectInput.addEventListener('click', function(e) {
      e.stopPropagation();
      dropdown.classList.toggle('open');
   });

   document.addEventListener('click', function(e) {
      if (!e.target.closest('#topic-select-wrapper')) {
         dropdown.classList.remove('open');
      }
   });

   languageTabs.forEach(function(tab) {
      tab.addEventListener('click', function() {
         languageTabs.forEach(function(t) { t.classList.remove('active'); });
         tab.classList.add('active');
         activeLanguage = tab.dataset.language;
         filterCards();
         updateUrl();
      });
   });

   function updateTopicTags() {
      tagsContainer.innerHTML = '';
      var placeholder = selectInput.querySelector('.topic-select-placeholder');
      var anyChecked = false;
      topicCheckboxes.forEach(function(cb) {
         if (cb.checked) {
            anyChecked = true;
            var tag = document.createElement('span');
            tag.className = 'topic-tag';
            tag.textContent = cb.value.replace(/-/g, ' ');
            var remove = document.createElement('span');
            remove.className = 'topic-tag-remove';
            remove.textContent = '×';
            remove.addEventListener('click', function() {
               cb.checked = false;
               updateTopicTags();
               filterCards();
               updateUrl();
            });
            tag.appendChild(remove);
            tagsContainer.appendChild(tag);
         }
      });
      if (placeholder) {
         var checkedCount = 0;
         topicCheckboxes.forEach(function(cb) { if (cb.checked) checkedCount++; });
         placeholder.textContent = checkedCount > 0 ? checkedCount + ' topic' + (checkedCount > 1 ? 's' : '') + ' selected' : 'Select topics...';
      }
   }

   function getChecked(type) {
      var values = [];
      allCheckboxes.forEach(function(cb) {
         if (cb.dataset.filterType === type && cb.checked) values.push(cb.value);
      });
      return values;
   }

   function matchesDuration(filter, duration) {
      var d = parseInt(duration, 10);
      if (isNaN(d)) return filter === 'long';
      if (filter === 'quick') return d < 10;
      if (filter === 'medium') return d >= 10 && d <= 20;
      if (filter === 'long') return d > 20;
      return false;
   }

   function filterCards() {
      var query = searchInput.value.toLowerCase().trim();
      var modes = getChecked('mode');
      var types = getChecked('type');
      var durations = getChecked('duration');
      var topics = getChecked('topic');
      var visibleCount = 0;

      cards.forEach(function(card) {
         var show = true;

         if (activeLanguage !== 'all' && card.dataset.language !== activeLanguage) show = false;

         if (show && modes.length > 0 && modes.indexOf(card.dataset.mode) === -1) show = false;

         if (show && types.length > 0 && types.indexOf(card.dataset.type) === -1) show = false;

         if (show && durations.length > 0) {
            var anyDuration = false;
            durations.forEach(function(d) {
               if (matchesDuration(d, card.dataset.duration)) anyDuration = true;
            });
            if (!anyDuration) show = false;
         }

         if (show && topics.length > 0) {
            var cardTopics = card.dataset.topics.split(',');
            var anyTopic = false;
            topics.forEach(function(t) {
               if (cardTopics.indexOf(t) !== -1) anyTopic = true;
            });
            if (!anyTopic) show = false;
         }

         if (show && query) {
            var text = card.dataset.title + ' ' + card.dataset.summary + ' ' + card.dataset.keywords;
            if (text.indexOf(query) === -1) show = false;
         }

         card.style.display = show ? '' : 'none';
         if (show) visibleCount++;
      });

      empty.style.display = visibleCount === 0 ? '' : 'none';
   }

   sidebarCheckboxes.forEach(function(cb) {
      cb.addEventListener('change', function() {
         filterCards();
         updateUrl();
      });
   });

   topicCheckboxes.forEach(function(cb) {
      cb.addEventListener('change', function() {
         updateTopicTags();
         filterCards();
         updateUrl();
      });
   });

   searchInput.addEventListener('input', function() {
      filterCards();
      updateUrl();
   });

   function updateUrl() {
      var params = new URLSearchParams();
      if (searchInput.value.trim()) params.set('q', searchInput.value.trim());
      if (activeLanguage !== 'all') params.set('language', activeLanguage);
      ['mode', 'type', 'duration', 'topic'].forEach(function(type) {
         var vals = getChecked(type);
         if (vals.length > 0) params.set(type, vals.join(','));
      });
      var qs = params.toString();
      var url = window.location.pathname + (qs ? '?' + qs : '');
      window.history.replaceState(null, '', url);
   }

   function applyUrlParams() {
      var params = new URLSearchParams(window.location.search);

      var q = params.get('q');
      if (q) searchInput.value = q;

      var lang = params.get('language');
      if (lang) {
         languageTabs.forEach(function(tab) {
            tab.classList.remove('active');
            if (tab.dataset.language === lang) {
               tab.classList.add('active');
               activeLanguage = lang;
            }
         });
      }

      ['mode', 'type', 'duration', 'topic'].forEach(function(type) {
         var val = params.get(type);
         if (!val) return;
         var vals = val.split(',');
         allCheckboxes.forEach(function(cb) {
            if (cb.dataset.filterType === type && vals.indexOf(cb.value) !== -1) {
               cb.checked = true;
            }
         });
      });

      if (params.get('topic')) updateTopicTags();
      if (params.toString()) filterCards();
   }

   applyUrlParams();
})();
