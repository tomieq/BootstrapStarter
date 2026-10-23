//
//  form.js
//

// Suggestions are bound on first focus, so it also works for fields loaded later.
$(document).on('focus', 'input[data-autocomplete-source]', function () {
    var input = $(this);
    if (input.data('ui-autocomplete')) {
        return;
    }
    var modal = input.closest('.modal-content');
    input.autocomplete({
        source: input.attr('data-autocomplete-source'),
        minLength: parseInt(input.attr('data-autocomplete-min-length') || '2', 10),
        appendTo: modal.length > 0 ? modal : 'body'
    });
});

function reloadDependentOptions(select) {
    var parent = $(document.getElementById(select.attr('data-depends-on')));
    var data = {};
    data[parent.attr('name') || parent.attr('id')] = parent.val();
    var token = (select.data('optionsToken') || 0) + 1;
    select.data('optionsToken', token);
    var wasDisabled = select.prop('disabled');
    select.prop('disabled', true);
    $.ajax({
        url: addTimestampToPath(select.attr('data-options-path')),
        data: data,
        dataType: 'html'
    }).done(function (html) {
        if (select.data('optionsToken') != token) {
            return;
        }
        var previous = select.val();
        select.html(html);
        select.val(previous);
        if (select.val() === null) {
            select.prop('selectedIndex', 0);
        }
        select.trigger('change');
    }).fail(function (jqxhr) {
        if (select.data('optionsToken') == token) {
            showError('Error while loading options: ' + jqxhr.status);
        }
    }).always(function () {
        if (select.data('optionsToken') == token) {
            select.prop('disabled', wasDisabled);
        }
    });
}

// Changing a field reloads the selects that depend on its id; reloaded selects fire change, so chains work.
$(document).on('change', '[id]', function () {
    var id = this.id;
    $('select[data-depends-on]').filter(function () {
        return $(this).attr('data-depends-on') == id;
    }).each(function () {
        reloadDependentOptions($(this));
    });
});

function escapeHtmlText(text) {
    return $('<div></div>').text(text).html();
}

function formatBytes(bytes) {
    if (bytes >= 1048576) {
        return (bytes / 1048576).toFixed(1).replace(/\.0$/, '') + ' MB';
    }
    if (bytes >= 1024) {
        return Math.round(bytes / 1024) + ' KB';
    }
    return bytes + ' B';
}

function setUploadProgress(bar, percent) {
    bar.attr('aria-valuenow', percent);
    bar.find('.progress-bar')
        .css('width', percent + '%')
        .text(percent + '%')
        .toggleClass('progress-bar-striped progress-bar-animated', percent >= 100);
}

// Posts the form as multipart/form-data and runs the JavaScript returned by the server, like submitFormInBackground.
function uploadFormInBackground(submitUrl, form) {
    var element = $(form)[0];
    var tooLarge = null;
    $(element).find('input[type=file][data-max-size]').each(function () {
        var max = parseInt($(this).attr('data-max-size'), 10);
        for (var i = 0; i < this.files.length; i++) {
            if (this.files[i].size > max) {
                tooLarge = { name: this.files[i].name, max: max };
            }
        }
    });
    if (tooLarge) {
        showError(escapeHtmlText(tooLarge.name) + ' is too large (max ' + formatBytes(tooLarge.max) + ')');
        return false;
    }
    var progress = $(element).find('[data-upload-progress]');
    var buttons = $(element).find('button[type=submit], input[type=submit]');
    setUploadProgress(progress, 0);
    progress.removeClass('d-none');
    buttons.prop('disabled', true);
    $.ajax({
        type: 'POST',
        url: addTimestampToPath(submitUrl),
        data: new FormData(element),
        processData: false,
        contentType: false,
        dataType: 'script',
        xhr: function () {
            var xhr = $.ajaxSettings.xhr();
            if (xhr.upload) {
                xhr.upload.addEventListener('progress', function (event) {
                    if (event.lengthComputable) {
                        setUploadProgress(progress, Math.round(event.loaded * 100 / event.total));
                    }
                });
            }
            return xhr;
        }
    }).fail(function (jqxhr, settings, exception) {
        if (jqxhr.status == 413) {
            showError('The upload is too large');
        } else {
            showError('Error while uploading ' + this.url + '<br>' + exception);
        }
    }).always(function () {
        buttons.prop('disabled', false);
        progress.addClass('d-none');
        setUploadProgress(progress, 0);
    });
    return false;
}
