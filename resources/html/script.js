// ==================== ENCAPSULACIÓN Y NAMESPACING ====================
const ThroatMicApp = (() => {
    // Variables privadas
    let currentProtectedFrequency = null;
    let currentService = null;
    let currentServicePrice = 0;
    let finishingOptions = {
        urgency: false,
        discretion: false,
        premium: false
    };

    // Configuración
    const CONFIG = {
        MAX_FREQUENCY: 1000,
        MIN_FREQUENCY: 1,
        MAX_PASSWORD_LENGTH: 50,
        NOTIFICATION_DURATION: 3000
    };

    // ==================== VALIDACIÓN ====================
    const Validators = {
        isValidFrequency: (freq) => {
            return typeof freq === 'number' && 
                   freq >= CONFIG.MIN_FREQUENCY && 
                   freq <= CONFIG.MAX_FREQUENCY;
        },

        isValidPassword: (password) => {
            if (typeof password !== 'string') return false;
            const len = password.length;
            return len > 0 && len <= CONFIG.MAX_PASSWORD_LENGTH;
        },

        isValidPrice: (price) => {
            return typeof price === 'number' && price >= 0 && price <= 999999;
        },

        isValidServiceId: (id) => {
            return typeof id === 'number' && id > 0;
        },

        isValidNUIData: (data) => {
            return data && typeof data === 'object';
        },

        isValidHUDData: (data) => {
            return this.isValidNUIData(data) &&
                   typeof data.frequency === 'number' &&
                   typeof data.battery === 'number' &&
                   typeof data.muted === 'boolean' &&
                   data.frequency >= CONFIG.MIN_FREQUENCY &&
                   data.frequency <= CONFIG.MAX_FREQUENCY &&
                   data.battery >= 0 &&
                   data.battery <= 100;
        }
    };

    // ==================== UTILIDADES ====================
    const Utils = {
        formatMoney: (amount) => {
            if (typeof amount !== 'number') return '$0';
            return '$' + Math.max(0, Math.floor(amount)).toLocaleString();
        },

        sanitizeText: (text) => {
            if (typeof text !== 'string') return '';
            return text.substring(0, 200).replace(/[<>]/g, '');
        },

        safeSetTextContent: (element, text) => {
            if (!element) return;
            element.textContent = this.sanitizeText(text);
        },

        showNotification: (message, type = 'info') => {
            if (typeof message !== 'string') return;
            
            const notification = document.createElement('div');
            notification.className = `notification notification-${type}`;
            notification.textContent = Utils.sanitizeText(message);
            notification.role = 'alert';
            notification.setAttribute('aria-live', 'polite');
            
            document.body.appendChild(notification);
            
            setTimeout(() => notification.classList.add('show'), 10);
            setTimeout(() => {
                notification.classList.remove('show');
                setTimeout(() => notification.remove(), 300);
            }, CONFIG.NOTIFICATION_DURATION);
        }
    };

    // ==================== THROAT MIC FUNCTIONS ====================
    const ThroatMic = {
        updateHUD: (data) => {
            if (!Validators.isValidHUDData(data)) {
                console.error('Invalid HUD data received');
                return;
            }

            const freqElement = document.getElementById('frequency');
            const batteryElement = document.getElementById('battery');
            const mutedElement = document.getElementById('mutedStatus');
            const transmittingElement = document.getElementById('transmittingStatus');

            if (freqElement) {
                Utils.safeSetTextContent(freqElement, data.frequency.toString());
            }

            if (batteryElement) {
                Utils.safeSetTextContent(batteryElement, data.battery + '%');
                batteryElement.className = 'hud-value ' + (
                    data.battery <= 15 ? 'battery-low' : 
                    data.battery <= 40 ? 'battery-medium' : 'battery-high'
                );
            }

            if (mutedElement) {
                mutedElement.style.display = data.muted ? 'flex' : 'none';
            }

            if (transmittingElement) {
                transmittingElement.style.display = data.transmitting ? 'block' : 'none';
            }

            const radioHUD = document.getElementById('radioHUD');
            if (radioHUD) {
                radioHUD.style.display = 'block';
            }
        },

        hideHUD: () => {
            const radioHUD = document.getElementById('radioHUD');
            if (radioHUD) {
                radioHUD.style.display = 'none';
            }
        },

        showFrequencyMenu: (frequencies) => {
            if (!frequencies || typeof frequencies !== 'object') {
                Utils.showNotification('Error: Datos de frecuencias inválidos', 'error');
                return;
            }

            const publicList = document.getElementById('publicList');
            const factionList = document.getElementById('factionList');
            const customList = document.getElementById('customList');
            const publicFreqs = document.getElementById('publicFreqs');
            const factionFreqs = document.getElementById('factionFreqs');
            const customFreqs = document.getElementById('customFreqs');

            // Limpiar listas
            if (publicList) publicList.innerHTML = '';
            if (factionList) factionList.innerHTML = '';
            if (customList) customList.innerHTML = '';

            // Frecuencias públicas
            if (frequencies.public && Array.isArray(frequencies.public.frequencies)) {
                frequencies.public.frequencies.forEach(freq => {
                    if (Validators.isValidFrequency(freq)) {
                        const btn = ThroatMic.createFrequencyButton(freq, freq, null);
                        if (publicList) publicList.appendChild(btn);
                    }
                });
                if (publicFreqs) publicFreqs.style.display = 'block';
            }

            // Frecuencias de facción
            if (frequencies.faction && Array.isArray(frequencies.faction.frequencies)) {
                frequencies.faction.frequencies.forEach(freq => {
                    if (Validators.isValidFrequency(freq)) {
                        const btn = ThroatMic.createFrequencyButton(freq, freq, null);
                        if (factionList) factionList.appendChild(btn);
                    }
                });
                if (factionFreqs) factionFreqs.style.display = 'block';
            }

            // Frecuencias personalizadas
            if (frequencies.custom && Array.isArray(frequencies.custom.frequencies)) {
                frequencies.custom.frequencies.forEach(freq => {
                    if (freq && typeof freq === 'object' && Validators.isValidFrequency(freq.number)) {
                        const displayText = String(freq.name || '').substring(0, 100);
                        const btn = ThroatMic.createFrequencyButton(
                            displayText + ' (' + freq.number + ')',
                            freq.number,
                            freq.password || null
                        );
                        if (customList) customList.appendChild(btn);
                    }
                });
                if (customFreqs) customFreqs.style.display = 'block';
            }

            const frequencyMenu = document.getElementById('frequencyMenu');
            if (frequencyMenu) {
                frequencyMenu.showModal();
            }
        },

        createFrequencyButton: (text, frequency, password) => {
            const btn = document.createElement('button');
            btn.className = 'freq-btn';
            btn.type = 'button';
            btn.textContent = Utils.sanitizeText(text);
            
            if (password) {
                btn.classList.add('locked');
                btn.setAttribute('aria-label', text + ' (protegida)');
            }
            
            btn.addEventListener('click', () => {
                if (password) {
                    ThroatMic.showPasswordModal(frequency, password);
                } else {
                    ThroatMic.selectFrequency(frequency);
                }
            });
            
            return btn;
        },

        showPasswordModal: (frequency, password) => {
            if (!Validators.isValidFrequency(frequency)) return;
            
            currentProtectedFrequency = frequency;
            const protectedFreqElement = document.getElementById('protectedFreq');
            const passwordInput = document.getElementById('passwordInput');
            const passwordModal = document.getElementById('passwordModal');
            
            if (protectedFreqElement) {
                Utils.safeSetTextContent(protectedFreqElement, frequency.toString());
            }
            
            if (passwordInput) {
                passwordInput.value = '';
                passwordInput.focus();
            }
            
            if (passwordModal) {
                passwordModal.showModal();
            }
        },

        selectFrequency: (frequency) => {
            if (!Validators.isValidFrequency(frequency)) {
                Utils.showNotification('Frecuencia inválida', 'error');
                return;
            }

            fetch('https://throatmic/selectFrequency', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ frequency: Math.floor(frequency) })
            })
            .then(response => {
                if (!response.ok) throw new Error('Network response error');
                return response.json();
            })
            .then(data => {
                if (data.success) {
                    Utils.showNotification('Conectado a frecuencia ' + frequency, 'success');
                    ThroatMic.hideFrequencyMenu();
                } else {
                    Utils.showNotification(data.message || 'Error al cambiar frecuencia', 'error');
                }
            })
            .catch(error => {
                console.error('Error:', error);
                Utils.showNotification('Error de conexión', 'error');
            });
        },

        hideFrequencyMenu: () => {
            const frequencyMenu = document.getElementById('frequencyMenu');
            if (frequencyMenu && frequencyMenu.open) {
                frequencyMenu.close();
            }
        }
    };

    // ==================== CORPORATE FUNCTIONS ====================
    const Corporate = {
        showMenu: (factionData, playerMoney, playerBank) => {
            if (!factionData || typeof factionData !== 'object') {
                Utils.showNotification('Error: Datos corporativos inválidos', 'error');
                return;
            }

            const corpName = document.getElementById('corpTitle');
            if (corpName) {
                Utils.safeSetTextContent(corpName, String(factionData.name || 'CORPORATE SYSTEM'));
            }

            const cashBalance = document.getElementById('cashBalance');
            if (cashBalance) {
                Utils.safeSetTextContent(cashBalance, Utils.formatMoney(playerMoney));
            }

            const bankBalance = document.getElementById('bankBalance');
            if (bankBalance) {
                Utils.safeSetTextContent(bankBalance, Utils.formatMoney(playerBank));
            }

            if (factionData.services && Array.isArray(factionData.services)) {
                Corporate.loadServices(factionData.services);
            }

            Corporate.showSection('services');

            const corporateMenu = document.getElementById('corporateMenu');
            if (corporateMenu) {
                corporateMenu.showModal();
            }
        },

        loadServices: (services) => {
            const servicesGrid = document.getElementById('servicesGrid');
            if (!servicesGrid) return;
            
            servicesGrid.innerHTML = '';

            services.forEach(service => {
                if (!service || typeof service !== 'object') return;
                if (!Validators.isValidServiceId(service.id) || !Validators.isValidPrice(service.price)) return;

                const serviceBtn = document.createElement('button');
                serviceBtn.className = 'service-btn';
                serviceBtn.type = 'button';
                
                const serviceName = Utils.sanitizeText(service.name || 'Desconocido');
                const servicePrice = Utils.formatMoney(service.price);
                const serviceLegal = service.legal ? 'LEGAL' : 'ILEGAL';
                const legalClass = service.legal ? 'service-legal' : 'service-illegal';

                serviceBtn.innerHTML = `
                    <div class="service-name">${serviceName}</div>
                    <div class="service-price">${servicePrice}</div>
                    <div class="${legalClass}">${serviceLegal}</div>
                `;

                serviceBtn.addEventListener('click', () => {
                    Corporate.selectService(service.id, service.price, service.name);
                });

                servicesGrid.appendChild(serviceBtn);
            });
        },

        selectService: (serviceId, price, name) => {
            if (!Validators.isValidServiceId(serviceId) || !Validators.isValidPrice(price)) {
                Utils.showNotification('Servicio inválido', 'error');
                return;
            }

            currentService = serviceId;
            currentServicePrice = Math.floor(price);

            const basePrice = document.getElementById('basePrice');
            if (basePrice) {
                Utils.safeSetTextContent(basePrice, Utils.formatMoney(currentServicePrice));
            }

            Corporate.updateTotal();
            Corporate.showSection('finishing');
        },

        confirmFinishing: () => {
            finishingOptions.urgency = document.getElementById('urgency')?.checked || false;
            finishingOptions.discretion = document.getElementById('discretion')?.checked || false;
            finishingOptions.premium = document.getElementById('premium')?.checked || false;

            Corporate.updateTotal();
            Corporate.showSection('total');
        },

        calculateTotal: () => {
            if (typeof currentServicePrice !== 'number') return 0;

            let finishingCost = 0;
            if (finishingOptions.urgency) finishingCost += 5000;
            if (finishingOptions.discretion) finishingCost += 8000;
            if (finishingOptions.premium) finishingCost += 12000;

            return Math.max(0, currentServicePrice + finishingCost);
        },

        updateTotal: () => {
            const total = Corporate.calculateTotal();
            const baseCost = currentServicePrice || 0;
            const finishingCost = total - baseCost;

            const finishingCostElement = document.getElementById('finishingCost');
            if (finishingCostElement) {
                Utils.safeSetTextContent(finishingCostElement, Utils.formatMoney(finishingCost));
            }

            const finalTotalElement = document.getElementById('finalTotal');
            if (finalTotalElement) {
                Utils.safeSetTextContent(finalTotalElement, Utils.formatMoney(total));
            }

            const availableFundsElement = document.getElementById('availableFunds');
            let availableFunds = 0;
            if (availableFundsElement) {
                const text = availableFundsElement.textContent || '$0';
                availableFunds = parseInt(text.replace('$', '').replace(/,/g, '')) || 0;
                Utils.safeSetTextContent(availableFundsElement, Utils.formatMoney(availableFunds));
            }

            const executeBtn = document.getElementById('executeBtn');
            if (executeBtn) {
                if (availableFunds >= total) {
                    executeBtn.disabled = false;
                    executeBtn.style.background = '#27ae60';
                } else {
                    executeBtn.disabled = true;
                    executeBtn.style.background = '#e74c3c';
                }
            }
        },

        executeService: () => {
            if (!currentService) {
                Utils.showNotification('Ningún servicio seleccionado', 'error');
                return;
            }

            const total = Corporate.calculateTotal();
            const availableFundsText = document.getElementById('availableFunds')?.textContent || '$0';
            const availableFunds = parseInt(availableFundsText.replace('$', '').replace(/,/g, '')) || 0;

            if (availableFunds < total) {
                Utils.showNotification('Fondos insuficientes', 'error');
                return;
            }

            fetch('https://throatmic/corporateSelectService', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    serviceId: Math.floor(currentService),
                    finishingOptions: finishingOptions
                })
            })
            .then(response => {
                if (!response.ok) throw new Error('Server error');
                return response.json();
            })
            .then(data => {
                if (data.success) {
                    Utils.showNotification('Servicio ejecutado: ' + Utils.formatMoney(data.amount), 'success');
                    setTimeout(() => Corporate.closeMenu(), 1500);
                } else {
                    Utils.showNotification(data.message || 'Error al ejecutar servicio', 'error');
                }
            })
            .catch(error => {
                console.error('Error:', error);
                Utils.showNotification('Error de conexión con el servidor', 'error');
            });
        },

        showSection: (sectionName) => {
            if (typeof sectionName !== 'string') return;

            // Ocultar todas las secciones
            document.querySelectorAll('.corporate-section').forEach(section => {
                section.hidden = true;
            });

            // Desactivar todos los tabs
            document.querySelectorAll('[role="tab"]').forEach(tab => {
                tab.classList.remove('active');
                tab.setAttribute('aria-selected', 'false');
            });

            // Mostrar sección activa
            const activeSection = document.getElementById(sectionName + 'Section');
            if (activeSection) {
                activeSection.hidden = false;
            }

            // Activar tab correspondiente
            const activeTab = document.getElementById(sectionName + 'Tab');
            if (activeTab) {
                activeTab.classList.add('active');
                activeTab.setAttribute('aria-selected', 'true');
            }

            if (sectionName === 'history') {
                Corporate.loadTransactionHistory();
            }
        },

        loadTransactionHistory: () => {
            fetch('https://throatmic/corporateGetHistory', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' }
            })
            .then(response => {
                if (!response.ok) throw new Error('Network error');
                return response.json();
            })
            .then(history => {
                if (!Array.isArray(history)) throw new Error('Invalid history format');

                const historyList = document.getElementById('historyList');
                if (!historyList) return;

                historyList.innerHTML = '';

                if (history.length === 0) {
                    historyList.textContent = 'No hay transacciones registradas';
                    return;
                }

                history.slice(0, 50).forEach(transaction => {
                    if (!transaction || typeof transaction !== 'object') return;

                    const historyItem = document.createElement('div');
                    historyItem.className = 'history-item';

                    const date = new Date(Math.min((transaction.timestamp || 0) * 1000, Date.now()));
                    const dateStr = date.toLocaleDateString() + ' ' + date.toLocaleTimeString();

                    const serviceDiv = document.createElement('div');
                    serviceDiv.className = 'history-service';
                    serviceDiv.textContent = Utils.sanitizeText(transaction.service || 'Desconocido');

                    const detailsDiv = document.createElement('div');
                    detailsDiv.className = 'history-details';

                    const factionSpan = document.createElement('span');
                    factionSpan.textContent = Utils.sanitizeText(transaction.faction || '');

                    const amountSpan = document.createElement('span');
                    amountSpan.textContent = Utils.formatMoney(transaction.amount || 0);

                    const dateSpan = document.createElement('span');
                    dateSpan.textContent = dateStr;

                    detailsDiv.appendChild(factionSpan);
                    detailsDiv.appendChild(amountSpan);
                    detailsDiv.appendChild(dateSpan);

                    historyItem.appendChild(serviceDiv);
                    historyItem.appendChild(detailsDiv);

                    historyList.appendChild(historyItem);
                });
            })
            .catch(error => {
                console.error('Error loading history:', error);
                const historyList = document.getElementById('historyList');
                if (historyList) {
                    historyList.textContent = 'Error al cargar historial';
                }
            });
        },

        triggerEmergency: () => {
            fetch('https://throatmic/corporateEmergency', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' }
            })
            .then(response => {
                if (response.ok) {
                    Utils.showNotification('Emergencia corporativa activada', 'warning');
                }
            })
            .catch(error => console.error('Error:', error));
        },

        closeMenu: () => {
            const corporateMenu = document.getElementById('corporateMenu');
            if (corporateMenu && corporateMenu.open) {
                corporateMenu.close();
            }

            fetch('https://throatmic/corporateClose', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' }
            })
            .catch(error => console.error('Error:', error));
        }
    };

    // ==================== EVENT LISTENERS ====================
    const initEventListeners = () => {
        // Menú de frecuencias
        document.getElementById('passwordForm')?.addEventListener('submit', (e) => {
            e.preventDefault();
            const passwordInput = document.getElementById('passwordInput');
            const password = passwordInput?.value || '';
            
            if (Validators.isValidPassword(password) && Validators.isValidFrequency(currentProtectedFrequency)) {
                fetch('https://throatmic/joinFrequencyWithPassword', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        frequency: Math.floor(currentProtectedFrequency),
                        password: password
                    })
                })
                .then(r => r.json())
                .then(data => {
                    if (data.success) {
                        Utils.showNotification('Conectado a frecuencia', 'success');
                        document.getElementById('passwordModal')?.close();
                    } else {
                        Utils.showNotification(data.message || 'Error', 'error');
                    }
                })
                .catch(e => {
                    console.error('Error:', e);
                    Utils.showNotification('Error de conexión', 'error');
                });
            } else {
                Utils.showNotification('Contraseña inválida', 'error');
            }
        });

        document.getElementById('cancelBtn')?.addEventListener('click', () => {
            document.getElementById('passwordModal')?.close();
            currentProtectedFrequency = null;
        });

        // Corporativo
        document.getElementById('closeCorpBtn')?.addEventListener('click', () => {
            Corporate.closeMenu();
        });

        document.getElementById('confirmBtn')?.addEventListener('click', () => {
            Corporate.confirmFinishing();
        });

        document.getElementById('executeBtn')?.addEventListener('click', () => {
            Corporate.executeService();
        });

        document.getElementById('emergencyBtn')?.addEventListener('click', () => {
            Corporate.triggerEmergency();
        });

        // Tabs
        document.querySelectorAll('[role="tab"]').forEach(tab => {
            tab.addEventListener('click', (e) => {
                const sectionId = e.target.getAttribute('aria-controls');
                if (sectionId) {
                    Corporate.showSection(sectionId.replace('Section', ''));
                }
            });
        });

        // Cerrar con ESC
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') {
                document.getElementById('frequencyMenu')?.close();
                document.getElementById('passwordModal')?.close();
                document.getElementById('corporateMenu')?.close();
            }
        });

        // Cambios en checkboxes
        document.getElementById('urgency')?.addEventListener('change', () => Corporate.updateTotal());
        document.getElementById('discretion')?.addEventListener('change', () => Corporate.updateTotal());
        document.getElementById('premium')?.addEventListener('change', () => Corporate.updateTotal());
    };

    // ==================== NUI MESSAGE HANDLER ====================
    window.addEventListener('message', (event) => {
        const data = event.data;

        if (!Validators.isValidNUIData(data)) return;

        const action = data.action;
        if (typeof action !== 'string') return;

        switch (action) {
            case 'updateHUD':
                ThroatMic.updateHUD(data);
                break;
            case 'hideHUD':
                ThroatMic.hideHUD();
                break;
            case 'showFrequencyMenu':
                ThroatMic.showFrequencyMenu(data.frequencies);
                break;
            case 'hideFrequencyMenu':
                ThroatMic.hideFrequencyMenu();
                break;
            case 'showCorporateMenu':
                Corporate.showMenu(data.factionData, data.playerMoney, data.playerBank);
                break;
        }
    });

    // ==================== INICIALIZACIÓN ====================
    window.addEventListener('DOMContentLoaded', () => {
        initEventListeners();
    });

    // API pública
    return {
        updateHUD: ThroatMic.updateHUD,
        hideHUD: ThroatMic.hideHUD,
        showFrequencyMenu: ThroatMic.showFrequencyMenu,
        hideFrequencyMenu: ThroatMic.hideFrequencyMenu,
        selectFrequency: ThroatMic.selectFrequency,
        showCorporateMenu: Corporate.showMenu,
        closeCorpMenu: Corporate.closeMenu,
        showSection: Corporate.showSection,
        executeService: Corporate.executeService
    };
})();

// Agregado para compatibilidad con búsquedas globales si es necesario
if (typeof window.TM === 'undefined') {
    window.TM = ThroatMicApp;
}