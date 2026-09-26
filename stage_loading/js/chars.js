var characters = [{slot:1,empty:true},{slot:2,empty:true},{slot:3,empty:true}];
var creatingSlot = 1;

function setCharacters(list) {
    if (!list || !list.length) {
        list = [{slot:1,empty:true},{slot:2,empty:true},{slot:3,empty:true}];
    }
    characters = list;
    for (var i = 1; i <= 3; i++) {
        var c = characters[i - 1];
        var el = document.getElementById('slot' + i);
        if (!el) continue;
        var slotDiv = el.parentElement;
        if (c && !c.empty && c.name) {
            slotDiv.classList.remove('empty');
            slotDiv.classList.add('filled');
            el.innerHTML =
                '<div class="char-name">' + escapeHtml(c.name) + ' ' + escapeHtml(c.surname) + '</div>' +
                '<div class="char-meta">' +
                'Yaş: ' + c.age + '<br>' +
                'Boy: ' + c.height + ' cm<br>' +
                'Skin: ' + c.skin + '<br>' +
                'Ülke: ' + escapeHtml(c.country) + '<br>' +
                'Para: $' + (c.money || 0) +
                '</div>';
        } else {
            slotDiv.classList.remove('filled');
            slotDiv.classList.add('empty');
            el.innerHTML = '<div class="empty-text">+ Boş Slot<br><small>Karakter Oluştur</small></div>';
        }
    }
    closeCreate();
}

function escapeHtml(s) {
    return String(s || '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

function onSlotClick(slot) {
    var c = characters[slot - 1];
    if (c && !c.empty && c.name) {
        showCharMsg('Spawn ediliyor...', true);
        if (typeof mta !== 'undefined') mta.triggerEvent('stageSelectChar', slot);
    } else {
        openCreate(slot);
    }
}

function openCreate(slot) {
    creatingSlot = slot;
    document.getElementById('createSlotLabel').innerText = '#' + slot;
    document.getElementById('createPanel').classList.remove('hidden');
    document.getElementById('charMsg').innerText = '';
    document.getElementById('cName').value = '';
    document.getElementById('cSurname').value = '';
    document.getElementById('cAge').value = '21';
    document.getElementById('cHeight').value = '175';
}

function closeCreate() {
    var p = document.getElementById('createPanel');
    if (p) p.classList.add('hidden');
}

function submitCreate() {
    var name = document.getElementById('cName').value.trim();
    var surname = document.getElementById('cSurname').value.trim();
    var age = parseInt(document.getElementById('cAge').value, 10);
    var height = parseInt(document.getElementById('cHeight').value, 10);
    var skin = parseInt(document.getElementById('cSkin').value, 10);
    var country = document.getElementById('cCountry').value;

    if (name.length < 2 || surname.length < 2) {
        showCharMsg('İsim ve soyisim en az 2 karakter!', false);
        return;
    }
    if (isNaN(age) || age < 16 || age > 80) {
        showCharMsg('Yaş 16-80 arası olmalı!', false);
        return;
    }
    if (isNaN(height) || height < 150 || height > 210) {
        showCharMsg('Boy 150-210 arası olmalı!', false);
        return;
    }

    showCharMsg('Oluşturuluyor...', true);
    if (typeof mta !== 'undefined') {
        mta.triggerEvent('stageCreateChar', creatingSlot, name, surname, age, height, skin, country);
    }
}

function showCharMsg(msg, ok) {
    var el = document.getElementById('charMsg');
    if (!el) return;
    el.innerText = msg || '';
    el.className = 'msg ' + (ok ? 'ok' : 'err');
}
window.showCharMsg = showCharMsg;
window.setCharacters = setCharacters;
