//
//  tabs.js
//

function loadLazyTab(pane, retry) {
    var path = pane.attr('data-lazy-path');
    var state = pane.attr('data-lazy-state');
    if (!path || state == 'loading' || state == 'loaded' || (state == 'failed' && !retry)) {
        return;
    }
    pane.attr('data-lazy-state', 'loading');
    $.get(addTimestampToPath(path), function (html) {
        pane.html(html);
        pane.attr('data-lazy-state', 'loaded');
    }, 'html').fail(function (jqxhr) {
        pane.attr('data-lazy-state', 'failed');
        showError('Error while loading tab: ' + jqxhr.status);
    });
}

function loadActiveLazyTabs() {
    $('.tab-pane.active[data-lazy-path]').each(function () {
        loadLazyTab($(this), false);
    });
}

function showTab(selector) {
    var trigger = $('[data-bs-target="' + selector + '"]').first();
    if (trigger.length > 0) {
        bootstrap.Tab.getOrCreateInstance(trigger[0]).show();
    }
}

$(document).on('shown.bs.tab', '[data-bs-toggle="tab"]', function (event) {
    loadLazyTab($($(event.target).attr('data-bs-target')), true);
});

// Fragments loaded later can contain an active lazy tab; it is picked up after each AJAX request.
$(document).ajaxComplete(loadActiveLazyTabs);
$(loadActiveLazyTabs);
