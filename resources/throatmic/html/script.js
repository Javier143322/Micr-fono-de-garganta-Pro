let currentProtectedFrequency = null;

window.addEventListener('message', function(event) {
    var data = event.data;
    
    if (data.action === 'updateHUD') {
        updateHUD(data);
    } else if (data.action === 'hideHUD') {
        hideHUD();
    } else if (data.action === 'transmitting') {
        updateTransmitting(data.state);
    } else if (data.action === 'showFrequencyMenu') {
        showFrequencyMenu(data.frequencies, data.currentFrequency);
    } else if (data.action === 'hideFrequencyMenu') {
        hideFrequencyMenu();
    }
});

function updateHUD(data) {
    document.getElementById('frequency').textContent = data.frequency;
    document.getElementById('battery').textContent = data.battery + '%';
    
    var batteryElement = document.getElementById('battery');
    batteryElement.className = 'hud-value ' + (
        data.battery <= 15 ? 'battery-low' : 
        data.battery <= 40 ? 'battery-medium' : 'battery-high'
    );
    
    var mutedElement = document.getElementById('mutedStatus');
    mutedElement.style.display = data.muted ? 'flex' : 'none';
    
    updateTransmitting(data.transmitting);
    document.getElementById('radioHUD').style.display = 'block';
}

function hideHUD() {
    document.getElementById('radioHUD').style.display = 'none';
}

function updateTransmitting(state) {
    var transmittingElement = document.getElementById('transmittingStatus');
    transmittingElement.style.display = state ? 'block' : 'none';
}

function showFrequencyMenu(frequencies, currentFreq) {
    // Limpiar listas
    document.getElementById('publicList').innerHTML = '';
    document.getElementById('factionList').innerHTML = '';
    document.getElementById('customList').innerHTML = '';
    
    // Frecuencias Públicas
    if (frequencies.public) {
        frequencies.public.frequencies.forEach(freq => {
            const btn = createFrequencyButton(freq, freq, currentFreq, null);
            document.getElementById('publicList').appendChild(btn);
        });
        document.getElementById('publicFreqs').style.display = 'block';
    }
    
    // Frecuencias de Facción
    if (frequencies.faction) {
        frequencies.faction.frequencies.forEach(freq => {
            const btn = createFrequencyButton(freq, freq, currentFreq, frequencies.faction.password);
            document.getElementById('factionList').appendChild(btn);
        });
        document.getElementById('factionFreqs').style.display = 'block';
    }
    
    // Frecuencias Personalizadas
    if (frequencies.custom) {
        frequencies.custom.frequencies.forEach(freq => {
            const displayText = `${freq.number} (${freq.name})`;
            const btn = createFrequencyButton(displayText, freq.number, currentFreq, freq.password);
            document.getElementById('customList').appendChild(btn);
        });
        document.getElementById('customFreqs').style.display = 'block';
    }
    
    document.getElementById('frequencyMenu').style.display = 'block';
}

function createFrequencyButton(text, frequency, currentFreq, password) {
    const btn = document.createElement('button');
    btn.className = 'freq-btn';
    btn.textContent = text;
    
    if (frequency === currentFreq) {
        btn.classList.add('current');
    }
    
    if (password) {
        btn.classList.add('locked');
    }
    
    btn.onclick = function() {
        if (password) {
            showPasswordModal(frequency, password);
        } else {
            selectFrequency(frequency);
        }
    };
    
    return btn;
}

function showPasswordModal(frequency, password) {
    currentProtectedFrequency = frequency;
    document.getElementById('protectedFreq').textContent = frequency;
    document.getElementById('passwordInput').value = '';
    document.getElementById('passwordModal').style.display = 'block';
    document.getElementById('passwordInput').focus();
}

function closeModal() {
    document.getElementById('passwordModal').style.display = 'none';
    currentProtectedFrequency = null;
}

function joinWithPassword() {
    const password = document.getElementById('passwordInput').value;
    if (password && currentProtectedFrequency) {
        fetch('https://throatmic/joinFrequencyWithPassword', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8',
            },
            body: JSON.stringify({
                frequency: currentProtectedFrequency,
                password: password
            })
        });
        closeModal();
    }
}

function selectFrequency(frequency) {
    fetch('https://throatmic/selectFrequency', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({
            frequency: frequency
        })
    });
}

function hideFrequencyMenu() {
    document.getElementById('frequencyMenu').style.display = 'none';
}

// Cerrar menú con ESC
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        hideFrequencyMenu();
        closeModal();
    }
});

// Cerrar menú al hacer click fuera
document.addEventListener('mousedown', function(event) {
    const menu = document.getElementById('frequencyMenu');
    const modal = document.getElementById('passwordModal');
    
    if (menu.style.display === 'block' && !menu.contains(event.target)) {
        hideFrequencyMenu();
    }
    
    if (modal.style.display === 'block' && !modal.contains(event.target)) {
        closeModal();
    }
});

// Enter para contraseña
document.getElementById('passwordInput').addEventListener('keypress', function(event) {
    if (event.key === 'Enter') {
        joinWithPassword();
    }
});
