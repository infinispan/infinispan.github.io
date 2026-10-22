function setTheme() {
  var storedTheme = localStorage.getItem('color-theme') || 'light';
  document.documentElement.dataset.storedTheme = storedTheme;
  var themeColor = '#ffffff';
  var isDark = storedTheme === 'dark' || (storedTheme === 'system' && window.matchMedia('(prefers-color-scheme: dark)').matches);
  if (isDark) {
    document.documentElement.classList.add('dark');
    themeColor = '#121212';
  } else {
    document.documentElement.classList.remove('dark');
  }
  var hljsLink = document.getElementById('hljs-theme');
  if (hljsLink) {
    hljsLink.href = isDark
      ? '//cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/github-dark.css'
      : '//cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/github.css';
  }
  return themeColor;
}

function toggleTheme() {
  var themeOrder = ['light', 'dark', 'system'];
  var storedTheme = localStorage.getItem('color-theme') || 'system';
  var newTheme = themeOrder[(themeOrder.indexOf(storedTheme) + 1) % themeOrder.length];
  localStorage.setItem('color-theme', newTheme);
  document.querySelector('meta[name="theme-color"]').content = setTheme();
  updateButton();
}

function updateButton() {
  var button = document.getElementById('theme-toggle');
  var storedTheme = localStorage.getItem('color-theme') || 'system';
  var themeTitles = {
    'dark': 'Color scheme: dark; next: system preferences',
    'light': 'Color scheme: light; next: dark',
    'system': 'Color scheme: system preferences; next: light'
  };
  button.setAttribute('aria-label', storedTheme);
  button.setAttribute('title', themeTitles[storedTheme]);
  return button;
}

var meta = document.createElement('meta');
meta.name = 'theme-color';
meta.content = setTheme();
document.head.appendChild(meta);

window.addEventListener('load', function() {
  var button = updateButton();
  button.addEventListener('click', toggleTheme);
});
