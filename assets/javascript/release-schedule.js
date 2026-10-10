(function () {
    var band = document.querySelector('.roadmap-content-band');
    if (!band) return;

    var now = new Date();
    var today = [now.getFullYear(), String(now.getMonth() + 1).padStart(2, '0'), String(now.getDate()).padStart(2, '0')].join('-');

    band.querySelectorAll('table td').forEach(function (cell) {
        var date = cell.textContent.trim();
        if (/^\d{4}-\d{2}-\d{2}$/.test(date) && date <= today) {
            cell.classList.add('past-date');
        }
    });
})();
