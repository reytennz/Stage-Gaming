const music = document.getElementById('bg-music');
const video = document.getElementById('bg-video');
const playBtn = document.getElementById('playBtn');
const prevBtn = document.getElementById('prevBtn');
const nextBtn = document.getElementById('nextBtn');
const volumeSlider = document.getElementById('volume');
const usernameInput = document.getElementById('username');
const passwordInput = document.getElementById('password');
const rememberCheck = document.getElementById('rememberMe');
let isPlaying = true;
let playlist = [];
let currentTrack = 0;

function localUrl(path) {
    if (!path) return '';
    if (/^https?:\/\//i.test(path)) return path;
    return 'http://mta/local/' + String(path).replace(/^\/+/, '');
}

function setTrack(index) {
    if (!playlist.length) return;
    currentTrack = (index + playlist.length) % playlist.length;
    var track = playlist[currentTrack] || {};
    document.getElementById('trackTitle').innerText = track.title || 'Stage Track';
    document.getElementById('trackArtist').innerText = track.artist || 'Stage Gaming';
    music.src = localUrl(track.url);
    music.load();
    if (isPlaying) music.play().catch(function(){});
}

window.applyStageConfig = function(cfg) {
    cfg = cfg || {};
    document.getElementById('serverName').innerText = cfg.brand || 'Stage Gaming';
    document.getElementById('discordText').innerText = cfg.discord || 'discord.gg/stagegaming';
    if (cfg.video && video) {
        var source = video.querySelector('source') || document.createElement('source');
        source.src = localUrl(cfg.video);
        source.type = 'video/mp4';
        if (!source.parentNode) video.appendChild(source);
        video.load();
        forceVideoPlay();
    }
    if (cfg.cover) {
        var cover = document.querySelector('.music-player .cover');
        if (cover) cover.src = localUrl(cfg.cover);
    }
    var vol = Number(cfg.volume);
    if (!isNaN(vol)) {
        music.volume = Math.max(0, Math.min(1, vol));
        volumeSlider.value = music.volume;
    }
    playlist = Array.isArray(cfg.playlist) ? cfg.playlist.filter(function(t) { return t && t.url; }) : [];
    setTrack(0);
};

function forceVideoPlay() {
    if (!video) return;
    try {
        video.muted = true;
        video.defaultMuted = true;
        video.volume = 0;
        video.loop = true;
        video.setAttribute('muted', '');
        video.setAttribute('autoplay', '');
        video.setAttribute('playsinline', '');
        video.load();
        var p = video.play();
        if (p && typeof p.then === 'function') {
            p.then(function() {
                // ok
            }).catch(function(err) {
                setTimeout(function() {
                    video.play().catch(function(){});
                }, 500);
            });
        }
    } catch (e) {}
}

try {
    var savedUser = localStorage.getItem('stage_user');
    var savedPass = localStorage.getItem('stage_pass');
    var savedRemember = localStorage.getItem('stage_remember');
    if (savedRemember === '1' && savedUser) {
        usernameInput.value = savedUser;
        if (savedPass) passwordInput.value = savedPass;
        rememberCheck.checked = true;
    }
} catch (e) {}

window.addEventListener('DOMContentLoaded', forceVideoPlay);
window.addEventListener('load', function() {
    forceVideoPlay();
    if (video) {
        video.addEventListener('loadeddata', forceVideoPlay);
        video.addEventListener('canplay', forceVideoPlay);
        video.addEventListener('error', function() {
            showError('Video yuklenemedi (codec/yol)');
        });
    }
    // surekli dene ilk 5 sn
    var tries = 0;
    var t = setInterval(function() {
        forceVideoPlay();
        tries++;
        if (tries > 10) clearInterval(t);
    }, 400);

    if (!playlist.length) {
        playlist = [{ title: 'Dark Thoughts', artist: 'Lil Tecca', url: 'assets/music.mp3' }];
        setTrack(0);
    }
    music.play().catch(function() {
        isPlaying = false;
        playBtn.innerText = '▶';
    });

    var progress = 0;
    var interval = setInterval(function() {
        progress += Math.random() * 7 + 2;
        if (progress >= 100) {
            progress = 100;
            clearInterval(interval);
            document.getElementById('loadingText').innerText = "Ready!";
        }
        document.getElementById('progress').style.width = progress + "%";
        document.getElementById('loadingText').innerText = "Loading assets... " + Math.floor(progress) + "%";
    }, 180);
});

document.body.addEventListener('click', forceVideoPlay);
document.body.addEventListener('mousedown', forceVideoPlay);

document.getElementById('btnLogin').addEventListener('click', function() { doLogin(false); });
document.getElementById('btnRegister').addEventListener('click', function() { doLogin(true); });

playBtn.addEventListener('click', function() {
    if (isPlaying) {
        music.pause();
        playBtn.innerText = '▶';
        isPlaying = false;
    } else {
        music.play();
        playBtn.innerText = '⏸';
        isPlaying = true;
    }
});

prevBtn.addEventListener('click', function() {
    setTrack(currentTrack - 1);
});

nextBtn.addEventListener('click', function() {
    setTrack(currentTrack + 1);
});

volumeSlider.addEventListener('input', function() {
    music.volume = this.value;
});

music.addEventListener('ended', function() {
    setTrack(currentTrack + 1);
});

passwordInput.addEventListener('keydown', function(e) {
    if (e.key === 'Enter') doLogin(false);
});
usernameInput.addEventListener('keydown', function(e) {
    if (e.key === 'Enter') passwordInput.focus();
});

function saveRemember(username, password) {
    try {
        if (rememberCheck.checked) {
            localStorage.setItem('stage_user', username);
            localStorage.setItem('stage_pass', password);
            localStorage.setItem('stage_remember', '1');
        } else {
            localStorage.removeItem('stage_user');
            localStorage.removeItem('stage_pass');
            localStorage.setItem('stage_remember', '0');
        }
    } catch (e) {}
}

function doLogin(isRegister) {
    var username = usernameInput.value.trim();
    var password = passwordInput.value;
    if (!username || !password) {
        showError("Kullanici adi ve sifre gerekli!");
        return;
    }
    if (username.length < 3 || password.length < 3) {
        showError("En az 3 karakter olmali!");
        return;
    }
    showError(isRegister ? "Kayit yapiliyor..." : "Giris yapiliyor...");
    saveRemember(username, password);
    forceVideoPlay();
    try {
        if (typeof mta !== 'undefined') {
            mta.triggerEvent("stageLogin", username, password, isRegister);
        } else {
            showError("mta objesi yok!");
        }
    } catch (err) {
        showError("JS hata: " + err.message);
    }
}

function showError(msg) {
    document.getElementById('errorMsg').innerText = msg || '';
}
window.showError = showError;
