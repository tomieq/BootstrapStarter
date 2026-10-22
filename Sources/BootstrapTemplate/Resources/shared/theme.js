//
//  theme.js
//  Loaded in <head> so the theme is applied before the first paint.
//

function applyTheme(theme) {
    if (theme == 'auto') {
        theme = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
    }
    if (theme == 'light' || theme == 'dark') {
        document.documentElement.setAttribute('data-bs-theme', theme);
    }
}

function setTheme(theme) {
    try {
        localStorage.setItem('theme', theme);
    } catch (e) {
    }
    applyTheme(theme);
}

function toggleTheme() {
    var current = document.documentElement.getAttribute('data-bs-theme');
    setTheme(current == 'dark' ? 'light' : 'dark');
}

(function () {
    var theme = null;
    try {
        theme = localStorage.getItem('theme');
    } catch (e) {
    }
    applyTheme(theme || document.documentElement.getAttribute('data-default-theme'));
})();
