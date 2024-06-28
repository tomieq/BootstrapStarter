//
//  notificications.js
//  
//
//  Created by Tomasz Kucharski on 18/03/2021.
//

function showError(txt, duration = 5000) {
    new Noty({
        text: txt,
        theme: 'metroui',
        layout: 'topRight',
        type: 'error',
        timeout: duration
    }).show();
    
}

function showWarning(txt, duration = 5000) {
    new Noty({
        text: txt,
        theme: 'metroui',
        layout: 'topRight',
        type: 'warning',
        timeout: duration
    }).show();
}

function showSuccess(txt, duration = 5000) {
    new Noty({
        text: txt,
        theme: 'metroui',
        layout: 'topRight',
        type: 'success',
        timeout: duration
    }).show();
}

function showInfo(txt, duration = 5000) {
    new Noty({
        text: txt,
        theme: 'metroui',
        layout: 'topRight',
        type: 'info',
        timeout: duration
    }).show();
}
