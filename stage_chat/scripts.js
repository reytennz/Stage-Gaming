const keyCodes = {
  enter: 13,
  tab: 9,
  up: 38,
  down: 40
};

const COMMAND_LIST = [
  { name: "/chat", help: "Chat konum/boyut/font ayarlari", params: "" },
  { name: "/me", help: "Karakter aksiyonu (mor, kafa ustu)", params: "[aksiyon]" },
  { name: "/do", help: "Ortam aciklamasi (yesil, kafa ustu)", params: "[aciklama]" },
  { name: "/pm", help: "Oyuncuya ozel mesaj gonder", params: "[ID] [mesaj]" },
  { name: "/msg", help: "Ozel mesaj (pm ile ayni)", params: "[ID] [mesaj]" },
  { name: "/a", help: "Admin sohbeti", params: "[mesaj]" },
  { name: "/duyuru", help: "Sunucu duyurusu", params: "[mesaj]" },
  { name: "/cv", help: "Arac olustur", params: "[model]" },
  { name: "/dv", help: "Icinde oldugun araci sil", params: "" },
  { name: "/dva", help: "Tum bos araclari sil", params: "" },
  { name: "/noon", help: "Saati 12:00 yap", params: "" },
  { name: "/night", help: "Saati 00:00 yap", params: "" },
  { name: "/kick", help: "Oyuncuyu sunucudan at", params: "[ID/isim] [sebep]" },
  { name: "/ban", help: "Oyuncuyu banla", params: "[ID/isim] [sebep]" },
  { name: "/goto", help: "Oyuncuya isinlan", params: "[ID/isim]" },
  { name: "/gethere", help: "Oyuncuyu yanina cek", params: "[ID/isim]" },
  { name: "/freeze", help: "Oyuncuyu dondur", params: "[ID/isim]" },
  { name: "/unfreeze", help: "Donmayi kaldir", params: "[ID/isim]" },
  { name: "/tp", help: "Koordinata isinlan", params: "[x] [y] [z]" },
  { name: "/invisible", help: "Gorunmez ol", params: "" },
  { name: "/myrank", help: "Admin rutbeni goster", params: "" },
  { name: "/givemoney", help: "Para ver", params: "[oyuncu] [miktar]" },
  { name: "/givecar", help: "Oyuncuya arac ver", params: "[oyuncu] [model]" },
  { name: "/admincommands", help: "Admin komut listesi", params: "" },
  { name: "/depoolustur", help: "Depo olustur", params: "" }
]

let suggestionIndex = 0;
let currentSuggestions = [];
let inputHistory = [];
let historyPos = -1;
let draftBeforeHistory = "";

function pushHistory(msg) {
  if (!msg || !msg.trim()) return;
  if (inputHistory[0] === msg) return;
  inputHistory.unshift(msg);
  if (inputHistory.length > 40) inputHistory.pop();
}

function historyUp() {
  if (!elements.input) return;
  if (currentSuggestions.length > 0) return false;
  if (inputHistory.length === 0) return true;
  if (historyPos === -1) draftBeforeHistory = elements.input.value;
  if (historyPos < inputHistory.length - 1) {
    historyPos++;
    elements.input.value = inputHistory[historyPos];
  }
  return true;
}

function historyDown() {
  if (!elements.input) return;
  if (currentSuggestions.length > 0) return false;
  if (historyPos <= 0) {
    historyPos = -1;
    elements.input.value = draftBeforeHistory || "";
    return true;
  }
  historyPos--;
  elements.input.value = inputHistory[historyPos];
  return true;
}


function updateSuggestions() {
  if (!elements || !elements.suggestions || !elements.input) return;
  const val = (elements.input.value || "");
  if (!val.startsWith("/")) {
    elements.suggestions.classList.add("hidden");
    elements.suggestions.innerHTML = "";
    currentSuggestions = [];
    return;
  }
  const lower = val.toLowerCase();
  if (lower === "/") {
    currentSuggestions = COMMAND_LIST.slice();
  } else {
    currentSuggestions = COMMAND_LIST.filter(function(c) {
      return c.name.indexOf(lower) === 0;
    });
  }
  if (currentSuggestions.length === 0) {
    elements.suggestions.classList.add("hidden");
    elements.suggestions.innerHTML = "";
    return;
  }
  if (suggestionIndex < 0) suggestionIndex = 0;
  if (suggestionIndex >= currentSuggestions.length) suggestionIndex = 0;

  elements.suggestions.innerHTML = "";
  const title = document.createElement("div");
  title.className = "chat__suggestions-title";
  title.textContent = "Komut listesi";
  elements.suggestions.appendChild(title);

  const maxShow = Math.min(currentSuggestions.length, 10);
  for (let i = 0; i < maxShow; i++) {
    const c = currentSuggestions[i];
    const div = document.createElement("div");
    div.className = "chat__suggestion" + (i === suggestionIndex ? " active" : "");
    const span = document.createElement("span");
    span.textContent = c.name + (c.params ? " " + c.params : "");
    div.appendChild(span);
    if (c.help) {
      const small = document.createElement("small");
      small.textContent = c.help;
      div.appendChild(small);
    }
    elements.suggestions.appendChild(div);
  }
  elements.suggestions.classList.remove("hidden");
}

function applySuggestion() {
  if (!currentSuggestions.length || !elements.input) return;
  const c = currentSuggestions[suggestionIndex] || currentSuggestions[0];
  elements.input.value = c.name + (c.params ? " " : " ");
  suggestionIndex = 0;
  updateSuggestions();
  elements.input.focus();
}


const state = {
  scroll: false,
  canScrollToBottom: true,
  lastRegisteredDelayCallback: null
};

const hexRegex = /#[0-9A-F]{6}/gi;

let elements;

function show(bool) {
  if (!bool) return elements.chat.classList.add("hidden");
  elements.chat.classList.remove("hidden");

  if (bool) {
    elements.input.addEventListener("keydown", preventPressTab);
  } else {
    elements.input.removeEventListener("keydown", preventPressTab);
  }

  scrollToBottom();
}

function showInput([definition]) {
  elements.input.value = "";
  elements.inputBlock.classList.remove("hidden");
  elements.input.style.paddingLeft = "2vh";

  setTimeout(() => {
    elements.input.focus();
    document.addEventListener("keydown", onKeydownEnterButton);
    document.addEventListener("click", onBlur);
  }, 0);
}

function hideInput() {
  if (elements.suggestions) elements.suggestions.classList.add("hidden");
  elements.inputBlock.classList.add("hidden");
  elements.input.blur();
  document.removeEventListener("keydown", onKeydownEnterButton);
  document.removeEventListener("click", onBlur);
}

function addMessage(message) {
  if (Array.isArray(message)) message = message[0];
  if (message === null || message === undefined) return;
  render(String(message));
  scrollToBottom();
}

function scrollToBottom(force = false) {
  if (force) {
    state.canScrollToBottom = true;
    state.lastRegisteredDelayCallback = null;
  }

  if (!state.canScrollToBottom) return;

  elements.chatMessages.scrollTo({
    top: elements.chatMessages.scrollHeight,
    behavior: "smooth"
  });
}

function preventPressTab(e) {
  if (e.keyCode == keyCodes.tab) e.preventDefault();
}

// renders message in chat container
function render(message) {
  const messageElement = document.createElement("div");
  messageElement.classList.add("chat__message");
  const messageFragment = document.createDocumentFragment();

  const processedText = processTextWithHexCode(message);
  for (let index = 0; index < processedText.length; index++) {
    const { text, color } = processedText[index];

    const partElement = document.createElement("span");
    partElement.innerText = text;
    if (color) partElement.style.color = color;
    messageFragment.appendChild(partElement);
  }

  messageElement.append(messageFragment);
  elements.chatMessagesContainer.append(messageElement);
}

function scroll(definition) {
  if (!state.scroll) return;
  const value = definition == "scrollup" ? -5 : 5;
  elements.chatMessages.scrollBy({ top: value });
  setTimeout(scroll, 25, definition);
}

function clear() {
  elements.chatMessagesContainer.innerHTML = "";
}

function processTextWithHexCode(text) {
  const results = [];
  const hexCodes = text.match(hexRegex);
  const parts = text.split(hexRegex);

  for (let i = 0; i < parts.length; i++) {
    const part = parts[i];
    if (part === "") continue;
    results.push({ text: part, color: i === 0 ? null : hexCodes[i - 1] });
  }

  return results;
}

// responds for automatic scrolling to bottom after some time if user didn't
// scroll manually yet
function registerDelayCallback() {
  state.canScrollToBottom = false;

  let callback = function() {
    if (!state.lastRegisteredDelayCallback) return;

    if (callback.uniqueId !== state.lastRegisteredDelayCallback.uniqueId) {
      return;
    }

    state.canScrollToBottom = true;
    scrollToBottom();
    state.lastRegisteredDelayCallback = null;
  };
  callback.uniqueId = Date.now();

  state.lastRegisteredDelayCallback = callback;
  setTimeout(callback, 5000);
}

// sends message to clientside
function onKeydownEnterButton(ev) {
  if (ev.keyCode !== keyCodes.enter) return;
  const val = elements.input.value;
  pushHistory(val);
  historyPos = -1;
  draftBeforeHistory = "";
  mta.triggerEvent("onChat2EnterButton", val);
  scrollToBottom(true);
}

function startScroll([definition]) {
  state.scroll = true;
  scroll(definition);
}

function onBlur() {
  elements.input.focus();
}

function stopScroll() {
  state.scroll = false;

  const isEndOfScroll =
    elements.chatMessages.scrollHeight -
      elements.chatMessages.scrollTop -
      parseInt(getComputedStyle(elements.chatMessages).height) <=
    1;

  if (isEndOfScroll) {
    state.canScrollToBottom = true;
    state.lastRegisteredDelayCallback = null;
    return;
  }

  registerDelayCallback();
}

function applyChatSettings(settings) {
  try {
    if (typeof settings === "string") settings = JSON.parse(settings);
  } catch (e) { return; }
  if (!settings) return;
  if (Array.isArray(settings)) settings = settings[0] || settings;
  const root = document.querySelector(".chat");
  if (!root) return;
  const scale = Number(settings.fontScale);
  const safeScale = (isFinite(scale) && scale > 0) ? scale : 1;
  root.style.setProperty("--font-scale", String(safeScale));
  // Sadece CSS degiskeni; documentElement fontSize dokunma (vh bozulmasin)

  const tr = settings.textR != null ? settings.textR : 255;
  const tg = settings.textG != null ? settings.textG : 255;
  const tb = settings.textB != null ? settings.textB : 255;
  root.style.setProperty("--text-color", "rgb(" + tr + "," + tg + "," + tb + ")");

  const br = settings.bgR != null ? settings.bgR : 10;
  const bg = settings.bgG != null ? settings.bgG : 12;
  const bb = settings.bgB != null ? settings.bgB : 18;
  const ba = settings.bgA != null ? settings.bgA : 220;
  root.style.setProperty("--bg-color", "rgba(" + br + "," + bg + "," + bb + "," + (ba/255) + ")");

  const ar = settings.accentR != null ? settings.accentR : 61;
  const ag = settings.accentG != null ? settings.accentG : 214;
  const ab = settings.accentB != null ? settings.accentB : 140;
  root.style.setProperty("--accent-color", "rgb(" + ar + "," + ag + "," + ab + ")");
}

function onDOMContentLoaded() {
  elements = {
    chat: document.querySelector(".chat"),
    inputBlock: document.querySelector(".chat__input-block"),
    inputLabel: document.querySelector(".chat__input-label"),
    input: document.querySelector(".chat__input"),
    chatMessages: document.querySelector(".chat__messages"),
    chatMessagesContainer: document.querySelector(".chat__messages-container")
  };

  elements.suggestions = document.getElementById("chatSuggestions");
  elements.settingsBtn = document.getElementById("chatSettingsBtn");

  if (elements.settingsBtn) {
    elements.settingsBtn.addEventListener("mousedown", function(ev) {
      ev.preventDefault();
      ev.stopPropagation();
      mta.triggerEvent("onChat2OpenSettings");
    });
    elements.settingsBtn.addEventListener("click", function(ev) {
      ev.preventDefault();
      ev.stopPropagation();
    });
  }

  elements.input.addEventListener("input", function() {
    suggestionIndex = 0;
    updateSuggestions();
  });

  elements.input.addEventListener("keydown", function(ev) {
    if (ev.keyCode === keyCodes.tab) {
      ev.preventDefault();
      applySuggestion();
      return;
    }
    if (ev.keyCode === keyCodes.up) {
      ev.preventDefault();
      if (currentSuggestions.length) {
        suggestionIndex = (suggestionIndex - 1 + currentSuggestions.length) % currentSuggestions.length;
        updateSuggestions();
      } else {
        historyUp();
      }
      return;
    }
    if (ev.keyCode === keyCodes.down) {
      ev.preventDefault();
      if (currentSuggestions.length) {
        suggestionIndex = (suggestionIndex + 1) % currentSuggestions.length;
        updateSuggestions();
      } else {
        historyDown();
      }
      return;
    }
    if (ev.keyCode === keyCodes.enter) return;
    if (ev.key === "Backspace" || ev.key === "Escape") return;
    if (ev.ctrlKey || ev.altKey || ev.metaKey) return;
    if (ev.key && ev.key.length === 1) {
      mta.triggerEvent("onChat2Typing");
    }
  });

  mta.triggerEvent("onChat2Loaded");
}

document.addEventListener("DOMContentLoaded", onDOMContentLoaded);
