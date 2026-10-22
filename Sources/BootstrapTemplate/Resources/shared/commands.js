//
//  commands.js
//

var pollTimers = {};

function refreshHtml(path, selector) {
    requestStarted();
    $(selector).load(addTimestampToPath(path), function (response, status, xhr) {
        if (status == 'error') {
            showError('Error while loading HTML: ' + xhr.status);
        }
    });
}

function startPolling(path, selector, intervalMs) {
    stopPolling(selector);
    pollTimers[selector] = setInterval(function () {
        if ($(selector).length == 0) {
            stopPolling(selector);
            return;
        }
        $.get(addTimestampToPath(path), function (html) {
            $(selector).html(html);
        }, 'html');
    }, intervalMs);
}

function stopPolling(selector) {
    if (pollTimers[selector]) {
        clearInterval(pollTimers[selector]);
        delete pollTimers[selector];
    }
}

function scrollToElement(selector) {
    var element = $(selector).first();
    if (element.length > 0) {
        element[0].scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
}

function copyToClipboard(text) {
    if (navigator.clipboard && window.isSecureContext) {
        navigator.clipboard.writeText(text).catch(function () {
            showError('Could not copy to clipboard');
        });
        return;
    }
    var area = $('<textarea style="position: fixed; opacity: 0"></textarea>').val(text).appendTo('body');
    area[0].select();
    try {
        document.execCommand('copy');
    } catch (e) {
        showError('Could not copy to clipboard');
    }
    area.remove();
}
