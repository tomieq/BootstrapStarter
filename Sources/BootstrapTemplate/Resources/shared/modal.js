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

function confirmDialog(options) {
    $('#confirmDialog').remove();
    var modal = $('<div class="modal fade" id="confirmDialog" tabindex="-1" aria-hidden="true">' +
        '<div class="modal-dialog modal-dialog-centered"><div class="modal-content">' +
        '<div class="modal-header"><h5 class="modal-title"></h5>' +
        '<button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button></div>' +
        '<div class="modal-body" style="white-space: pre-line"></div>' +
        '<div class="modal-footer"><button type="button" class="btn btn-secondary cancel-button" data-bs-dismiss="modal"></button>' +
        '<button type="button" class="btn confirm-button"></button></div>' +
        '</div></div></div>');
    modal.find('.modal-title').text(options.title);
    modal.find('.modal-body').text(options.message);
    modal.find('.cancel-button').text(options.cancelLabel);
    modal.find('.confirm-button').addClass(options.confirmClass).text(options.confirmLabel);
    var confirmed = false;
    modal.find('.confirm-button').on('click', function () {
        confirmed = true;
        bootstrap.Modal.getOrCreateInstance(modal[0]).hide();
    });
    // The action runs after the dialog is gone so it can open another modal.
    modal.on('hidden.bs.modal', function () {
        var instance = bootstrap.Modal.getInstance(modal[0]);
        if (instance) {
            instance.dispose();
        }
        modal.remove();
        if (confirmed) {
            options.onConfirm();
        }
    });
    $('body').append(modal);
    bootstrap.Modal.getOrCreateInstance(modal[0]).show();
}
