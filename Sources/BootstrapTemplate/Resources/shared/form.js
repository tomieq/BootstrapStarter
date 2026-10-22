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
