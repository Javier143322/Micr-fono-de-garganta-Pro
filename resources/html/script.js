// ==================== SISTEMA THROAT MIC ====================
let currentProtectedFrequency = null;

// ==================== SISTEMA CORPORATE ====================
let currentService = null;
let currentServicePrice = 0;
let finishingOptions = {
    urgency: false,
    discretion: false,
    premium: false
};

// ==================== EVENTOS PRINCIPALES ====================
window.addEventListener('message', function(event) {
    var data = event.data;
    
    // Sistema Throat Mic
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
    
    // Sistema Corporate
    else if (data.action === 'showCorporateMenu') {
        showCorporateMenu(data.factionData, data.playerMoney, data.playerBank);
    }
});

// ==================== FUNCIONES THROAT MIC ====================
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
    document.getElementById('publicList').innerHTML = '';
    document.getElementById('factionList').innerHTML = '';
    document.getElementById('customList').innerHTML = '';
    
    if (frequencies.public) {
        frequencies.public.frequencies.forEach(freq => {
            const btn = createFrequencyButton(freq, freq, currentFreq, null);
            document.getElementById('publicList').appendChild(btn);
        });
        document.getElementById('publicFreqs').style.display = 'block';
    }
    
    if (frequencies.faction) {
        frequencies.faction.frequencies.forEach(freq => {
            const btn = createFrequencyButton(freq, freq, currentFreq, frequencies.faction.password);
            document.getElementById('factionList').appendChild(btn);
        });
        document.getElementById('factionFreqs').style.display = 'block';
    }
    
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

// ==================== FUNCIONES CORPORATE ====================
function showCorporateMenu(factionData, playerMoney, playerBank) {
    document.getElementById('corpName').textContent = factionData.name;
    document.getElementById('cashBalance').textContent = '$' + playerMoney;
    document.getElementById('bankBalance').textContent = '$' + playerBank;
    
    loadServices(factionData.services);
    showSection('services');
    document.getElementById('corporateMenu').style.display = 'block';
}

function loadServices(services) {
    const servicesGrid = document.getElementById('servicesGrid');
    servicesGrid.innerHTML = '';
    
    services.forEach(service => {
        const serviceBtn = document.createElement('div');
        serviceBtn.className = 'service-btn';
        serviceBtn.onclick = () => selectService(service.id, service.price, service.name);
        
        serviceBtn.innerHTML = `
            <div class="service-name">${service.name}</div>
            <div class="service-price">$${service.price}</div>
            <div class="${service.legal ? 'service-legal' : 'service-illegal'}">
                ${service.legal ? 'LEGAL' : 'ILEGAL'}
            </div>
        `;
        
        servicesGrid.appendChild(serviceBtn);
    });
}

function selectService(serviceId, price, name) {
    currentService = serviceId;
    currentServicePrice = price;
    
    document.getElementById('basePrice').textContent = '$' + price;
    updateTotal();
    
    showSection('finishing');
}

function confirmFinishing() {
    finishingOptions.urgency = document.getElementById('urgency').checked;
    finishingOptions.discretion = document.getElementById('discretion').checked;
    finishingOptions.premium = document.getElementById('premium').checked;
    
    updateTotal();
    showSection('total');
}

function updateTotal() {
    let finishingCost = 0;
    if (finishingOptions.urgency) finishingCost += 5000;
    if (finishingOptions.discretion) finishingCost += 8000;
    if (finishingOptions.premium) finishingCost += 12000;
    
    const total = currentServicePrice + finishingCost;
    
    document.getElementById('finishingCost').textContent = '$' + finishingCost;
    document.getElementById('finalTotal').textContent = '$' + total;
    
    const availableFunds = parseInt(document.getElementById('cashBalance').textContent.replace('$', ''));
    document.getElementById('availableFunds').textContent = '$' + availableFunds;
    
    const executeBtn = document.querySelector('.execute-btn');
    if (availableFunds >= total) {
        executeBtn.disabled = false;
        executeBtn.style.background = '#27ae60';
    } else {
        executeBtn.disabled = true;
        executeBtn.style.background = '#e74c3c';
    }
}

function executeService() {
    if (!currentService) return;
    
    fetch('https://throatmic/corporateSelectService', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({
            serviceId: currentService,
            finishingOptions: finishingOptions
        })
    });
    
    closeCorporate();
}

function showSection(sectionName) {
    document.querySelectorAll('.corporate-section').forEach(section => {
        section.classList.remove('active');
    });
    document.querySelectorAll('.nav-btn').forEach(btn => {
        btn.classList.remove('active');
    });
    
    document.getElementById(sectionName + 'Section').classList.add('active');
    document.querySelector(`.nav-btn[onclick="showSection('${sectionName}')"]`).classList.add('active');
    
    if (sectionName === 'history') {
        loadTransactionHistory();
    }
}

function loadTransactionHistory() {
    fetch('https://throatmic/corporateGetHistory', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        }
    })
    .then(response => response.json())
    .then(history => {
        const historyList = document.getElementById('historyList');
        historyList.innerHTML = '';
        
        if (history.length === 0) {
            historyList.innerHTML = '<div class="history-item">No hay transacciones registradas</div>';
            return;
        }
        
        history.forEach(transaction => {
            const historyItem = document.createElement('div');
            historyItem.className = 'history-item';
            
            const date = new Date(transaction.timestamp * 1000);
            const dateStr = date.toLocaleDateString() + ' ' + date.toLocaleTimeString();
            
            historyItem.innerHTML = `
                <div class="history-service">${transaction.service}</div>
                <div class="history-details">
                    <span>${transaction.faction}</span>
                    <span>$${transaction.amount}</span>
                    <span>${dateStr}</span>
                </div>
            `;
            
            historyList.appendChild(historyItem);
        });
    });
}

function triggerEmergency() {
    fetch('https://throatmic/corporateEmergency', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        }
    });
}

function closeCorporate() {
    document.getElementById('corporateMenu').style.display = 'none';
    fetch('https://throatmic/corporateClose', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        }
    });
}

// ==================== EVENTOS GLOBALES ====================
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        hideFrequencyMenu();
        closeModal();
        closeCorporate();
    }
});

document.getElementById('passwordInput').addEventListener('keypress', function(event) {
    if (event.key === 'Enter') {
        joinWithPassword();
    }
});

// Cerrar menús al hacer click fuera
document.addEventListener('mousedown', function(event) {
    const frequencyMenu = document.getElementById('frequencyMenu');
    const corporateMenu = document.getElementById('corporateMenu');
    const passwordModal = document.getElementById('passwordModal');
    
    if (frequencyMenu.style.display === 'block' && !frequencyMenu.contains(event.target)) {
        hideFrequencyMenu();
    }
    
    if (corporateMenu.style.display === 'block' && !corporateMenu.contains(event.target)) {
        closeCorporate();
    }
    
    if (passwordModal.style.display === 'block' && !passwordModal.contains(event.target)) {
        closeModal();
    }
});