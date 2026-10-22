//
//  modal.js
//

function modalContainer() {
    var container = $('#modalContainer');
    if (container.length == 0) {
        container = $('<div id="modalContainer"></div>').appendTo('body');
    }
    return container;
}

function disposeLoadedModals() {
    modalContainer().find('.modal').each(function () {
        var instance = bootstrap.Modal.getInstance(this);
        if (instance) {
            instance.dispose();
        }
    });
    modalContainer().empty();
    $('.modal-backdrop').remove();
    $('body').removeClass('modal-open').css({ overflow: '', paddingRight: '' });
}

function showModal(selector) {
    var element = $(selector).first();
    if (element.length > 0) {
        bootstrap.Modal.getOrCreateInstance(element[0]).show();
    }
}

function hideModals() {
    $('.modal.show').each(function () {
        var instance = bootstrap.Modal.getInstance(this);
        if (instance) {
            instance.hide();
        }
    });
}

function loadModal(path) {
    requestStarted();
    $.get(addTimestampToPath(path), function (html) {
        disposeLoadedModals();
        var container = modalContainer();
        container.html(html);
        var element = container.find('.modal').first();
        if (element.length == 0) {
            return;
        }
        element.on('hidden.bs.modal', function () {
            var instance = bootstrap.Modal.getInstance(this);
            if (instance) {
                instance.dispose();
            }
            $(this).remove();
        });
        bootstrap.Modal.getOrCreateInstance(element[0]).show();
    }, 'html').fail(function (jqxhr) {
        showError('Error while loading modal: ' + jqxhr.status);
    });
}
