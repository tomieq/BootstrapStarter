function submitFormInBackground(submitUrl, form) {
    var formData = $(form);
    $.ajax({
          type: "POST",
          url: submitUrl,
          data: formData.serialize(),
          dataType: "script"
        });
    return false;
}
