let selectedHud = 1;
let selectedSpeedo = 1;
let selectedFont = 1;
let selectedHealth = 1;
let selectedCross = 0;

function openChars() {
    if (typeof mta !== 'undefined') mta.triggerEvent('stageMenuAction', 'chars');
}

function openSettings() {
    document.getElementById('mainButtons').style.display = 'none';
    document.getElementById('settingsPanel').classList.remove('hidden');
}

function backToMain() {
    document.getElementById('settingsPanel').classList.add('hidden');
    document.getElementById('mainButtons').style.display = 'flex';
}

function selectHud(id) {
    selectedHud = id;
    document.querySelectorAll('#hudOptions .option-card').forEach(function(el) {
        el.classList.toggle('active', parseInt(el.getAttribute('data-hud'), 10) === id);
    });
}

function selectSpeedo(id) {
    selectedSpeedo = id;
    document.querySelectorAll('#speedoOptions .option-card').forEach(function(el) {
        el.classList.toggle('active', parseInt(el.getAttribute('data-speedo'), 10) === id);
    });
}

function selectFont(id) {
    selectedFont = id;
    document.querySelectorAll('#fontOptions .option-card').forEach(function(el) {
        el.classList.toggle('active', parseInt(el.getAttribute('data-font'), 10) === id);
    });
}

function selectNameBar(id) {
    selectHealth(id || 1);
}

function selectHealth(id) {
    selectedHealth = id;
    document.querySelectorAll('#healthOptions .option-card').forEach(function(el) {
        el.classList.toggle('active', parseInt(el.getAttribute('data-health'), 10) === id);
    });
}

function selectCross(id) {
    selectedCross = id;
    document.querySelectorAll('#crossOptions .option-card').forEach(function(el) {
        el.classList.toggle('active', parseInt(el.getAttribute('data-cross'), 10) === id);
    });
}

function saveAndClose() {
    if (typeof mta !== 'undefined') {
        mta.triggerEvent('stageMenuAction', 'saveHud',
            selectedHud, selectedSpeedo, selectedFont, selectedHealth, selectedCross);
    }
    closeMenu();
}

function closeMenu() {
    if (typeof mta !== 'undefined') mta.triggerEvent('stageMenuAction', 'close');
}

window.setHudSelection = function(hud, speedo, font, nameBar, cross) {
    selectHud(hud || 1);
    selectSpeedo(speedo || 1);
    selectFont(font || 1);
    selectHealth(nameBar || 1);
    selectCross(cross || 0);
};
